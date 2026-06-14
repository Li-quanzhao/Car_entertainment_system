#include "grpc_client_adapter.h"

#include <QJsonDocument>
#include <QJsonArray>
#include <QDebug>

// ============================================================
// gRPC 模式实现
// ============================================================
#ifdef CAR_HMI_USE_GRPC

#include <grpcpp/grpcpp.h>
#include "proto/car_assistant.pb.h"
#include "proto/car_assistant.grpc.pb.h"

GrpcClientAdapter::GrpcClientAdapter(QObject *parent)
    : QObject(parent)
{
}

GrpcClientAdapter::~GrpcClientAdapter() = default;

void GrpcClientAdapter::setServerAddress(const QString &address)
{
    if (m_serverAddress != address) {
        m_serverAddress = address;
        m_stub.reset(); // 强制重建 channel
        m_channel.reset();
        emit serverAddressChanged(m_serverAddress);
    }
}

void GrpcClientAdapter::ensureChannel()
{
    if (!m_channel) {
        m_channel = grpc::CreateChannel(
            m_serverAddress.toStdString(),
            grpc::InsecureChannelCredentials());
        m_stub = car_assistant::CarAssistant::NewStub(m_channel);
    }
}

void GrpcClientAdapter::healthCheck(Callback callback)
{
    ensureChannel();

    car_assistant::Empty request;
    car_assistant::HealthResponse response;
    grpc::ClientContext context;

    auto status = m_stub->GetHealth(&context, request, &response);

    bool ok = status.ok();
    m_connected = ok;

    if (ok) {
        QJsonObject obj;
        obj["status"] = QString::fromStdString(response.status());
        obj["llm_available"] = response.llm_available();
        obj["tools_count"] = static_cast<int>(response.tools_count());
        obj["version"] = QString::fromStdString(response.version());
        if (callback) callback(true, obj);
    } else {
        if (callback) callback(false, QJsonObject());
    }
    emit connectedChanged(m_connected);
}

void GrpcClientAdapter::sendChat(const QString &message, const QString &sessionId,
                                  Callback callback)
{
    ensureChannel();

    car_assistant::ChatRequest request;
    request.set_session_id(sessionId.toStdString());
    request.set_message(message.toStdString());

    car_assistant::ChatResponse response;
    grpc::ClientContext context;

    auto status = m_stub->ChatQuery(&context, request, &response);

    if (status.ok()) {
        QString reply = QString::fromStdString(response.reply());
        emit chatResponseReceived(reply);

        QJsonObject obj;
        obj["reply"] = reply;
        obj["session_id"] = QString::fromStdString(response.session_id());
        if (callback) callback(true, obj);
    } else {
        QString err = QString::fromStdString(status.error_message());
        emit errorOccurred(err);
        if (callback) callback(false, QJsonObject());
    }
}

void GrpcClientAdapter::sendChatStream(const QString &message, const QString &sessionId)
{
    ensureChannel();

    car_assistant::ChatRequest request;
    request.set_session_id(sessionId.toStdString());
    request.set_message(message.toStdString());

    grpc::ClientContext context;
    auto reader = m_stub->StreamChat(&context, request);

    car_assistant::ChatResponse response;
    while (reader->Read(&response)) {
        if (response.is_streaming()) {
            emit chatStreamChunk(QString::fromStdString(response.reply()));
        }
    }
    auto status = reader->Finish();
    if (!status.ok()) {
        emit errorOccurred(QString::fromStdString(status.error_message()));
    }
    emit chatStreamFinished();
}

void GrpcClientAdapter::sendCommand(const QString &command, const QJsonObject &args,
                                     Callback callback)
{
    ensureChannel();

    car_assistant::ToolRequest request;
    request.set_tool_name(command.toStdString());
    for (auto it = args.begin(); it != args.end(); ++it) {
        (*request.mutable_parameters())[it.key().toStdString()] =
            it.value().toString().toStdString();
    }

    car_assistant::ToolResponse response;
    grpc::ClientContext context;

    auto status = m_stub->ExecuteTool(&context, request, &response);

    if (status.ok()) {
        QJsonObject obj;
        obj["success"] = response.success();
        obj["data"] = QJsonDocument::fromJson(
            QByteArray::fromStdString(response.data())).object();
        if (callback) callback(true, obj);
    } else {
        QString err = QString::fromStdString(status.error_message());
        emit errorOccurred(err);
        if (callback) callback(false, QJsonObject());
    }
}

// ============================================================
// 非 gRPC 模式 — 退化桩实现
// ============================================================
#else

GrpcClientAdapter::GrpcClientAdapter(QObject *parent)
    : QObject(parent)
{
}

GrpcClientAdapter::~GrpcClientAdapter() = default;

void GrpcClientAdapter::setServerAddress(const QString &address)
{
    if (m_serverAddress != address) {
        m_serverAddress = address;
        emit serverAddressChanged(m_serverAddress);
    }
}

void GrpcClientAdapter::healthCheck(Callback callback)
{
    qWarning() << "[GrpcClientAdapter] gRPC not available (CAR_HMI_USE_GRPC not defined)."
               << "Use AgentHttpClient instead.";
    if (callback) callback(false, QJsonObject());
}

void GrpcClientAdapter::sendChat(const QString &, const QString &,
                                  Callback callback)
{
    qWarning() << "[GrpcClientAdapter] gRPC not available.";
    if (callback) callback(false, QJsonObject());
}

void GrpcClientAdapter::sendChatStream(const QString &, const QString &)
{
    qWarning() << "[GrpcClientAdapter] gRPC not available.";
}

void GrpcClientAdapter::sendCommand(const QString &, const QJsonObject &,
                                     Callback callback)
{
    qWarning() << "[GrpcClientAdapter] gRPC not available.";
    if (callback) callback(false, QJsonObject());
}

#endif // CAR_HMI_USE_GRPC
