#include "agent_viewmodel.h"
#include "service/agent_http_client.h"

AgentViewModel::AgentViewModel(AgentHttpClient *client, QObject *parent)
    : QObject(parent)
    , m_client(client)
    , m_sessionId(QStringLiteral("hmi-session"))
{
    // 连接 Agent 流式响应信号
    connect(m_client, &AgentHttpClient::chatStreamChunk,
            this, &AgentViewModel::onStreamChunk);
    connect(m_client, &AgentHttpClient::chatStreamFinished,
            this, &AgentViewModel::onStreamFinished);
    connect(m_client, &AgentHttpClient::errorOccurred,
            this, &AgentViewModel::onError);
    connect(m_client, &AgentHttpClient::connectedChanged,
            this, &AgentViewModel::connectedChanged);

    // 首次检查连接状态
    checkConnection();
}

void AgentViewModel::sendMessage(const QString &text)
{
    if (text.trimmed().isEmpty() || m_thinking)
        return;

    // 添加用户消息
    appendMessage(QStringLiteral("user"), text.trimmed());

    // 添加占位助手消息（文本会在流式响应中逐步填充）
    m_streamAccumulator.clear();
    appendMessage(QStringLiteral("assistant"), QString());

    // 显示思考中状态
    m_thinking = true;
    emit thinkingChanged(true);

    // 发送流式请求
    m_client->sendChatStream(text.trimmed(), m_sessionId);
}

void AgentViewModel::clearMessages()
{
    m_messages.clear();
    m_streamAccumulator.clear();
    emit messagesChanged();
}

void AgentViewModel::checkConnection()
{
    m_client->healthCheck();
}

void AgentViewModel::appendMessage(const QString &role, const QString &text)
{
    QVariantMap msg;
    msg[QStringLiteral("role")] = role;
    msg[QStringLiteral("text")] = text;
    m_messages.append(msg);
    emit messagesChanged();
}

void AgentViewModel::updateLastMessage(const QString &text)
{
    if (m_messages.isEmpty())
        return;

    QVariantMap msg = m_messages.last().toMap();
    msg[QStringLiteral("text")] = text;
    m_messages.last() = msg;
    emit messagesChanged();
}

void AgentViewModel::onStreamChunk(const QString &chunk)
{
    m_streamAccumulator += chunk;
    updateLastMessage(m_streamAccumulator);
}

void AgentViewModel::onStreamFinished()
{
    m_thinking = false;
    emit thinkingChanged(false);
}

void AgentViewModel::onError(const QString &errorText)
{
    m_thinking = false;
    emit thinkingChanged(false);

    // 移除空的占位助手消息，替换为错误消息
    if (!m_messages.isEmpty()) {
        QVariantMap last = m_messages.last().toMap();
        if (last.value(QStringLiteral("role")).toString() == QLatin1String("assistant")
            && last.value(QStringLiteral("text")).toString().isEmpty()) {
            m_messages.removeLast();
        }
    }

    appendMessage(QStringLiteral("error"), errorText);
}
