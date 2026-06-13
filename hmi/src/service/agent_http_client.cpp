#include "agent_http_client.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QUrlQuery>

AgentHttpClient::AgentHttpClient(QObject *parent)
    : QObject(parent)
    , m_manager(new QNetworkAccessManager(this))
    , m_baseUrl("http://localhost:8000")
{
}

AgentHttpClient::~AgentHttpClient() = default;

void AgentHttpClient::setBaseUrl(const QString &url)
{
    if (m_baseUrl != url) {
        m_baseUrl = url;
        emit baseUrlChanged(url);
    }
}

QNetworkReply *AgentHttpClient::get(const QString &endpoint)
{
    QNetworkRequest request(QUrl(m_baseUrl + endpoint));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    return m_manager->get(request);
}

QNetworkReply *AgentHttpClient::post(const QString &endpoint, const QJsonObject &body)
{
    QNetworkRequest request(QUrl(m_baseUrl + endpoint));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    QByteArray data = QJsonDocument(body).toJson(QJsonDocument::Compact);
    return m_manager->post(request, data);
}

void AgentHttpClient::healthCheck(Callback callback)
{
    QNetworkReply *reply = get("/api/health");
    connect(reply, &QNetworkReply::finished, this, [this, reply, callback]() {
        onHealthCheckFinished(reply, callback);
    });
}

void AgentHttpClient::sendChat(const QString &message, const QString &sessionId,
                                Callback callback)
{
    QJsonObject body;
    body["message"]    = message;
    body["session_id"] = sessionId;
    QNetworkReply *reply = post("/api/chat", body);
    connect(reply, &QNetworkReply::finished, this, [this, reply, callback]() {
        onChatFinished(reply, callback);
    });
}

void AgentHttpClient::sendChatStream(const QString &message, const QString &sessionId)
{
    QJsonObject body;
    body["message"]    = message;
    body["session_id"] = sessionId;
    QNetworkReply *reply = post("/api/chat/stream", body);

    // SSE 缓冲区
    auto *buffer = new QByteArray();

    connect(reply, &QNetworkReply::readyRead, this, [this, reply, buffer]() {
        buffer->append(reply->readAll());

        // 按 \n\n 分隔解析 SSE 事件
        while (true) {
            int idx = buffer->indexOf("\n\n");
            if (idx < 0) break;

            QByteArray event = buffer->left(idx);
            buffer->remove(0, idx + 2);

            // 解析 data: 行
            QStringList lines = QString::fromUtf8(event).split('\n');
            for (const QString &line : lines) {
                if (!line.startsWith("data: ")) continue;
                QString jsonStr = line.mid(6); // 去掉 "data: "
                QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8());
                if (!doc.isObject()) continue;
                QJsonObject obj = doc.object();

                if (obj.contains("done") && obj["done"].toBool()) {
                    emit this->chatStreamFinished();
                } else if (obj.contains("text")) {
                    emit this->chatStreamChunk(obj["text"].toString());
                }
            }
        }
    });

    connect(reply, &QNetworkReply::finished, this, [this, reply, buffer]() {
        // 处理剩余缓冲区数据
        if (buffer && !buffer->isEmpty()) {
            QString remaining = QString::fromUtf8(*buffer);
            if (remaining.startsWith("data: ")) {
                QString jsonStr = remaining.mid(6);
                QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8());
                if (doc.isObject()) {
                    QJsonObject obj = doc.object();
                    if (obj.contains("done") && obj["done"].toBool()) {
                        emit this->chatStreamFinished();
                    }
                }
            }
        }
        delete buffer;
        reply->deleteLater();
    });
}

void AgentHttpClient::sendCommand(const QString &command, const QJsonObject &args,
                                   Callback callback)
{
    QJsonObject body;
    body["command"] = command;
    body["args"] = args;
    QNetworkReply *reply = post("/api/command", body);
    connect(reply, &QNetworkReply::finished, this, [this, reply, callback]() {
        onCommandFinished(reply, callback);
    });
}

void AgentHttpClient::onHealthCheckFinished(QNetworkReply *reply, Callback callback)
{
    bool success = false;
    QJsonObject resp;

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (doc.isObject()) {
            resp = doc.object();
            success = true;
        }
    }

    m_connected = success;
    emit connectedChanged(success);

    if (!success) {
        QString err = reply->errorString();
        emit errorOccurred(QStringLiteral("Agent 连接失败: %1").arg(err));
    }

    if (callback) callback(success, resp);
    reply->deleteLater();
}

void AgentHttpClient::onCommandFinished(QNetworkReply *reply, Callback callback)
{
    bool success = false;
    QJsonObject resp;

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (doc.isObject()) {
            resp = doc.object();
            success = resp["success"].toBool();
            emit commandResponseReceived(resp["message"].toString());
        }
    } else {
        emit errorOccurred(QStringLiteral("Agent 命令执行失败: %1")
                           .arg(reply->errorString()));
    }

    if (callback) callback(success, resp);
    reply->deleteLater();
}

void AgentHttpClient::onChatFinished(QNetworkReply *reply, Callback callback)
{
    bool success = false;
    QJsonObject resp;

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (doc.isObject()) {
            resp = doc.object();
            success = true;
            QString replyText = resp["reply"].toString();
            if (!replyText.isEmpty()) {
                emit chatResponseReceived(replyText);
            }
        }
    } else {
        emit errorOccurred(QStringLiteral("Agent 请求失败: %1")
                           .arg(reply->errorString()));
    }

    if (callback) callback(success, resp);
    reply->deleteLater();
}
