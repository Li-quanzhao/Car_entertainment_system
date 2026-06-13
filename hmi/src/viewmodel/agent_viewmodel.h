#ifndef AGENT_VIEWMODEL_H
#define AGENT_VIEWMODEL_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QTimer>

class AgentHttpClient;

class AgentViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList messages READ messages NOTIFY messagesChanged)
    Q_PROPERTY(bool thinking READ thinking NOTIFY thinkingChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

public:
    explicit AgentViewModel(AgentHttpClient *client, QObject *parent = nullptr);

    QVariantList messages() const { return m_messages; }
    bool thinking() const { return m_thinking; }
    bool connected() const { return m_connected; }

public slots:
    void sendMessage(const QString &text);
    void clearMessages();
    void checkConnection();

signals:
    void messagesChanged();
    void thinkingChanged(bool thinking);
    void connectedChanged(bool connected);

private:
    void appendMessage(const QString &role, const QString &text);
    void updateLastMessage(const QString &text);
    void onStreamChunk(const QString &chunk);
    void onStreamFinished();
    void onError(const QString &errorText);

    QVariantList m_messages;
    AgentHttpClient *m_client;
    bool m_thinking = false;
    bool m_connected = false;
    QString m_sessionId;
    QString m_streamAccumulator;  // 流式累积文本
};

#endif // AGENT_VIEWMODEL_H
