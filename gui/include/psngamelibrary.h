// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
#pragma once
#include <QObject>
#include <QVariantList>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class PsnGameLibrary : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList games READ games NOTIFY changed)
    Q_PROPERTY(State state READ state NOTIFY changed)
public:
    enum State { Idle, Loading, Ready, SignInRequired, Forbidden, RateLimited, Unavailable };
    Q_ENUM(State)
    explicit PsnGameLibrary(QObject *parent = nullptr, QNetworkAccessManager *transport = nullptr);
    QVariantList games() const { return titles; }
    State state() const { return current; }
    void refresh(const QString &token);
    void clear();
signals:
    void changed();
private:
    QNetworkAccessManager *network;
    QNetworkReply *pending = nullptr;
    QVariantList titles;
    State current = Idle;
};
