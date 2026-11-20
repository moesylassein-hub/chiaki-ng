// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
#include "psngamelibrary.h"
#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>
#include <QUrl>

static QUrl artwork(const QString &value)
{
    const QUrl url(value, QUrl::StrictMode);
    const QString host = url.host().toLower();
    if (!url.isValid() || url.scheme() != "https" || !url.userInfo().isEmpty() ||
        url.port(443) != 443 || (!host.endsWith(".playstation.com") && !host.endsWith(".playstation.net")))
        return {};
    return url;
}

static QVariantList recentTitles(const QJsonArray &items)
{
    QVariantList result;
    QSet<QString> ids;
    for (const auto &item : items) {
        const auto game = item.toObject();
        const auto category = game.value("category").toString();
        if (category != "ps4_game" && category != "ps5_native_game")
            continue;
        const auto id = game.value("titleId").toString().trimmed();
        auto name = game.value("localizedName").toString().trimmed();
        if (name.isEmpty())
            name = game.value("name").toString().trimmed();
        if (id.isEmpty() || ids.contains(id) || name.isEmpty())
            continue;
        ids.insert(id);
        auto image = artwork(game.value("localizedImageUrl").toString());
        if (image.isEmpty())
            image = artwork(game.value("imageUrl").toString());
        result.append(QVariantMap{{"id", id}, {"title", name.left(256)}, {"image", image},
                                  {"platform", category == "ps4_game" ? "PS4" : "PS5"},
                                  {"lastPlayed", QDateTime::fromString(game.value("lastPlayedDateTime").toString(), Qt::ISODate)}});
        if (result.size() >= 12)
            break;
    }
    return result;
}

PsnGameLibrary::PsnGameLibrary(QObject *parent, QNetworkAccessManager *transport)
    : QObject(parent), network(transport ? transport : new QNetworkAccessManager(this)) {}

void PsnGameLibrary::clear()
{
    if (pending) {
        auto *old = pending;
        pending = nullptr;
        old->abort();
    }
    if (current != Idle || !titles.isEmpty()) {
        titles.clear();
        current = Idle;
        emit changed();
    }
}

void PsnGameLibrary::refresh(const QString &token)
{
    if (pending)
        return;
    if (token.isEmpty()) {
        titles.clear();
        current = SignInRequired;
        emit changed();
        return;
    }
    const QUrl url(QStringLiteral("https://m.np.playstation.com/api/gamelist/v2/users/me/titles?limit=12&categories=ps4_game,ps5_native_game"));
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);
    request.setTransferTimeout(10000);
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("Authorization", "Bearer " + token.toUtf8());
    auto *reply = pending = network->get(request);
    constexpr qint64 byteLimit = 512 * 1024;
    reply->setReadBufferSize(byteLimit + 1);
    connect(reply, &QIODevice::readyRead, reply, [reply] {
        if (reply->bytesAvailable() > byteLimit)
            reply->abort();
    });
    current = Loading;
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        reply->deleteLater();
        if (reply != pending)
            return;
        pending = nullptr;
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (status == 401) {
            titles.clear();
            current = SignInRequired;
        } else if (status == 403) {
            titles.clear();
            current = Forbidden;
        } else if (status == 429) {
            current = RateLimited;
        } else if (status != 200 || reply->error() != QNetworkReply::NoError || reply->bytesAvailable() > byteLimit) {
            current = Unavailable;
        } else {
            const auto array = QJsonDocument::fromJson(reply->readAll()).object().value("titles");
            if (array.isArray()) {
                titles = recentTitles(array.toArray());
                current = Ready;
            } else {
                current = Unavailable;
            }
        }
        emit changed();
    });
    emit changed();
}
