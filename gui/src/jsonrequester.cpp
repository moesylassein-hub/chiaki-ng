#include "jsonrequester.h"
#include <QJsonParseError>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>

namespace {
constexpr int kRequestTimeoutMs = 10000;
}

JsonRequester::JsonRequester(QObject* parent) : QObject(parent), networkManager(new QNetworkAccessManager(this)) {
    connect(networkManager, &QNetworkAccessManager::finished, this, &JsonRequester::onRequestFinished);
}

QString JsonRequester::generateBearerAuthHeader(QString bearerToken) {
    return QString("Bearer %1").arg(bearerToken);
}

QString JsonRequester::generateBasicAuthHeader(QString username, QString password) {
    const QString combined = username + QStringLiteral(":") + password;
    QString authHeader = "Basic " + combined.toUtf8().toBase64();
    return authHeader;
}

void JsonRequester::makePostRequest(const QString& url, const QString& authHeader, const QString contentType,
                                    const QString body) {
    makeRequest(true, url, authHeader, contentType, body);
}

void JsonRequester::makeGetRequest(const QString& url, const QString& authHeader, const QString contentType) {
    makeRequest(false, url, authHeader, contentType, QString());
}

void JsonRequester::makeRequest(bool post, const QString& url, const QString& authHeader, const QString contentType,
                                const QString body) {
    QUrl q_url(url);
    if (!q_url.isValid() || q_url.scheme().isEmpty()) {
        emit requestError(url, QStringLiteral("Invalid request URL"), QNetworkReply::ProtocolInvalidOperationError);
        return;
    }

    QNetworkRequest request(q_url);
    request.setRawHeader("Authorization", authHeader.toUtf8());
    request.setRawHeader("Content-Type", contentType.toUtf8());

    QNetworkReply* reply;
    if (post) {
        QByteArray postData = body.toUtf8();
        reply = networkManager->post(request, postData);
    } else {
        reply = networkManager->get(request);
    }

    QTimer* timeoutTimer = new QTimer(reply);
    timeoutTimer->setSingleShot(true);
    connect(timeoutTimer, &QTimer::timeout, reply, [reply]() {
        if (!reply->isFinished()) {
            reply->setProperty("timed_out", true);
            reply->abort();
        }
    });
    timeoutTimer->start(kRequestTimeoutMs);

    currentReplies.insert(reply, url);
}

void JsonRequester::onRequestFinished(QNetworkReply* reply) {
    const QString url = currentReplies.value(reply);
    currentReplies.remove(reply);

    if (reply->error() == QNetworkReply::NoError) {
        const QByteArray data = reply->readAll();
        QJsonParseError parseError;
        const QJsonDocument jsonDocument = QJsonDocument::fromJson(data, &parseError);

        if (parseError.error != QJsonParseError::NoError) {
            emit requestError(url,
                              QStringLiteral("Invalid JSON response: %1").arg(parseError.errorString()),
                              QNetworkReply::UnknownContentError);
            reply->deleteLater();
            return;
        }

        emit requestFinished(url, jsonDocument);
    } else {
        const bool timedOut = reply->property("timed_out").toBool();
        const QString errorString = timedOut ? QStringLiteral("Request timed out") : reply->errorString();
        emit requestError(url, errorString, reply->error());
    }

    reply->deleteLater();
}
