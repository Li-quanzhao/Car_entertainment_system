#ifndef AGENT_HTTP_CLIENT_H
#define AGENT_HTTP_CLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QUrl>
#include <functional>

class AgentHttpClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString baseUrl READ baseUrl WRITE setBaseUrl NOTIFY baseUrlChanged)
    Q_PROPERTY(QString authKey READ authKey WRITE setAuthKey NOTIFY authKeyChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

public:
    using Callback = std::function<void(bool success, const QJsonObject &response)>;

    explicit AgentHttpClient(QObject *parent = nullptr);
    ~AgentHttpClient() override;

    QString baseUrl() const { return m_baseUrl; }
    void setBaseUrl(const QString &url);

    QString authKey() const { return m_authKey; }
    void setAuthKey(const QString &key);

    bool connected() const { return m_connected; }

    // 发送聊天消息
    void sendChat(const QString &message, const QString &sessionId = QString(),
                  Callback callback = nullptr);

    // 流式聊天（SSE）
    void sendChatStream(const QString &message, const QString &sessionId = QString());

    // 健康检查
    void healthCheck(Callback callback = nullptr);

    // 发送 Agent 命令（语音唤醒后直接调用）
    void sendCommand(const QString &command, const QJsonObject &args = QJsonObject(),
                     Callback callback = nullptr);

signals:
    void baseUrlChanged(const QString &url);
    void authKeyChanged(const QString &key);
    void connectedChanged(bool connected);
    void chatResponseReceived(const QString &reply);
    void commandResponseReceived(const QString &message);
    void errorOccurred(const QString &error);

    // 流式响应信号
    void chatStreamChunk(const QString &text);
    void chatStreamFinished();

private slots:
    void onHealthCheckFinished(QNetworkReply *reply, Callback callback);
    void onChatFinished(QNetworkReply *reply, Callback callback);
    void onCommandFinished(QNetworkReply *reply, Callback callback);

private:
    QNetworkAccessManager *m_manager;
    QString m_baseUrl;
    QString m_authKey;
    bool m_connected = false;

    QNetworkReply *get(const QString &endpoint);
    QNetworkReply *post(const QString &endpoint, const QJsonObject &body);
    void setAuthHeader(QNetworkRequest &request) const;
};

#endif // AGENT_HTTP_CLIENT_H
