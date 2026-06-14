#ifndef GRPC_CLIENT_ADAPTER_H
#define GRPC_CLIENT_ADAPTER_H

// ============================================================
// C++ gRPC Client Adapter
// 条件编译：仅在 CAR_HMI_USE_GRPC 定义且找到 gRPC 库时启用。
// 否则退化为桩（stub），编译为空操作。
// ============================================================

#include <QObject>
#include <QJsonObject>
#include <functional>
#include <memory>
#include <string>

// ── 前向声明（避免未安装 gRPC 时编译错误）────────────────────
#ifdef CAR_HMI_USE_GRPC
namespace grpc {
class Channel;
class ClientContext;
}  // namespace grpc

namespace car_assistant {
class CarAssistant;
class CarAssistantStub;
}  // namespace car_assistant
#endif

class GrpcClientAdapter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString serverAddress READ serverAddress WRITE setServerAddress NOTIFY serverAddressChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

public:
    using Callback = std::function<void(bool success, const QJsonObject &response)>;

    explicit GrpcClientAdapter(QObject *parent = nullptr);
    ~GrpcClientAdapter() override;

    QString serverAddress() const { return m_serverAddress; }
    void setServerAddress(const QString &address);

    bool connected() const { return m_connected; }

    // 发送聊天消息
    void sendChat(const QString &message, const QString &sessionId = QString(),
                  Callback callback = nullptr);

    // 流式聊天（gRPC Server-Side Streaming）
    void sendChatStream(const QString &message, const QString &sessionId = QString());

    // 健康检查
    void healthCheck(Callback callback = nullptr);

    // 发送 Agent 命令
    void sendCommand(const QString &command, const QJsonObject &args = QJsonObject(),
                     Callback callback = nullptr);

signals:
    void serverAddressChanged(const QString &address);
    void connectedChanged(bool connected);
    void chatResponseReceived(const QString &reply);
    void commandResponseReceived(const QString &message);
    void errorOccurred(const QString &error);

    // 流式响应信号
    void chatStreamChunk(const QString &text);
    void chatStreamFinished();

private:
    QString m_serverAddress = "localhost:50051";
    bool m_connected = false;

#ifdef CAR_HMI_USE_GRPC
    std::unique_ptr<car_assistant::CarAssistantStub> m_stub;
    std::shared_ptr<grpc::Channel> m_channel;

    void ensureChannel();
#endif
};

#endif // GRPC_CLIENT_ADAPTER_H
