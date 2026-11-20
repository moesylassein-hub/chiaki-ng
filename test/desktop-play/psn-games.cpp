// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
#include "psngamelibrary.h"
#include <QCoreApplication>
#include <QNetworkRequest>
#include <cassert>
#include <cstring>

class Reply final : public QNetworkReply {
public:
    QByteArray body;
    int pos = 0;
    explicit Reply(const QNetworkRequest &req, QObject *parent) : QNetworkReply(parent) {
        setUrl(req.url());
        setRequest(req);
        open(QIODevice::ReadOnly);
    }
    void complete(int status, QByteArray data) {
        body = data;
        setAttribute(QNetworkRequest::HttpStatusCodeAttribute, status);
        emit readyRead();
        if (!isFinished()) { setFinished(true); emit finished(); }
    }
    void abort() override {
        setError(OperationCanceledError, "aborted");
        if (!isFinished()) { setFinished(true); emit finished(); }
    }
    qint64 bytesAvailable() const override { return body.size() - pos + QIODevice::bytesAvailable(); }
    bool isSequential() const override { return true; }
protected:
    qint64 readData(char *out, qint64 max) override {
        qint64 n = qMin<qint64>(max, body.size()-pos);
        if (n <= 0) return -1;
        memcpy(out, body.constData()+pos, n);
        pos += n;
        return n;
    }
};
class Transport final : public QNetworkAccessManager {
public:
    Reply *last = nullptr;
    int requests = 0;
protected:
    QNetworkReply *createRequest(Operation op, const QNetworkRequest &req, QIODevice *) override {
        ++requests;
        assert(op == GetOperation);
        assert(req.url().host() == "m.np.playstation.com" && req.url().path().endsWith("/users/me/titles"));
        assert(req.attribute(QNetworkRequest::RedirectPolicyAttribute) == QNetworkRequest::ManualRedirectPolicy);
        assert(req.rawHeader("Authorization") == "Bearer fixture");
        return last = new Reply(req, this);
    }
};

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    Transport network;
    PsnGameLibrary library(nullptr, &network);
    library.refresh({});
    assert(network.requests == 0 && library.state() == PsnGameLibrary::SignInRequired);
    library.refresh("fixture");
    library.refresh("fixture");
    assert(network.requests == 1 && library.state() == PsnGameLibrary::Loading);
    network.last->complete(200, R"({"titles":[
        {"titleId":"id","name":"Game","localizedName":"Local game","category":"ps5_native_game","imageUrl":"https://image.api.playstation.com/art.jpg","lastPlayedDateTime":"2025-03-03T17:10:00Z"},
        {"titleId":"id","name":"Duplicate","category":"ps5_native_game"},
        {"titleId":"else","name":"Other","category":"unknown"},
        {"titleId":"ps4","name":"Second","category":"ps4_game","localizedImageUrl":"file:///private"}
    ]})");
    assert(library.state() == PsnGameLibrary::Ready && library.games().size() == 2);
    assert(library.games()[0].toMap()["title"].toString() == "Local game");
    assert(library.games()[0].toMap()["image"].toUrl().host() == "image.api.playstation.com");
    assert(library.games()[1].toMap()["image"].toUrl().isEmpty());
    library.refresh("fixture");
    network.last->complete(429, {});
    assert(library.state() == PsnGameLibrary::RateLimited && library.games().size() == 2);
    library.refresh("fixture");
    network.last->complete(401, {});
    assert(library.state() == PsnGameLibrary::SignInRequired && library.games().isEmpty());
    library.refresh("fixture");
    library.clear();
    assert(library.state() == PsnGameLibrary::Idle && network.last->isFinished());
    library.refresh("fixture");
    network.last->complete(403, {});
    assert(library.state() == PsnGameLibrary::Forbidden);
    library.refresh("fixture");
    network.last->complete(200, QByteArray(600*1024, 'x'));
    assert(library.state() == PsnGameLibrary::Unavailable);
}
