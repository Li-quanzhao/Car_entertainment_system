#include "serial_port_adapter.h"
#include <QDebug>

SerialPortAdapter::SerialPortAdapter(QObject *parent)
    : QObject(parent)
    , m_handle(INVALID_HANDLE_VALUE)
    , m_readTimer(new QTimer(this))
{
    connect(m_readTimer, &QTimer::timeout, this, &SerialPortAdapter::onReadReady);
}

SerialPortAdapter::~SerialPortAdapter()
{
    close();
}

bool SerialPortAdapter::open(const QString &portName, quint32 baudRate)
{
    if (isOpen()) {
        close();
    }

    m_portName = portName;

    // 1. 打开串口
    QString fullName = QStringLiteral("\\\\.\\%1").arg(portName);
    m_handle = CreateFileA(
        fullName.toStdString().c_str(),
        GENERIC_READ | GENERIC_WRITE,
        0,                          // 独占访问
        nullptr,                    // 默认安全属性
        OPEN_EXISTING,
        FILE_FLAG_NO_BUFFERING,     // 无缓冲，提高实时性
        nullptr);

    if (m_handle == INVALID_HANDLE_VALUE) {
        DWORD err = GetLastError();
        emit errorOccurred(QStringLiteral("打开串口失败: %1 (错误码: %2)")
                               .arg(portName)
                               .arg(err));
        return false;
    }

    // 2. 配置串口参数
    if (!configurePort(baudRate)) {
        CloseHandle(m_handle);
        m_handle = INVALID_HANDLE_VALUE;
        return false;
    }

    // 3. 设置超时
    if (!setTimeouts()) {
        CloseHandle(m_handle);
        m_handle = INVALID_HANDLE_VALUE;
        return false;
    }

    // 4. 清空缓冲区
    PurgeComm(m_handle, PURGE_RXCLEAR | PURGE_TXCLEAR);

    // 5. 启动轮询读取（每 50ms 检查一次）
    m_readTimer->start(50);

    emit connectionChanged(true);
    qDebug() << "串口已打开:" << portName << "@" << baudRate;
    return true;
}

void SerialPortAdapter::close()
{
    m_readTimer->stop();

    if (m_handle != INVALID_HANDLE_VALUE) {
        CloseHandle(m_handle);
        m_handle = INVALID_HANDLE_VALUE;
        qDebug() << "串口已关闭:" << m_portName;
    }

    m_portName.clear();
    emit connectionChanged(false);
}

qint64 SerialPortAdapter::read(QByteArray &buffer)
{
    if (!isOpen()) {
        return -1;
    }

    DWORD bytesRead = 0;
    char temp[4096];

    if (ReadFile(m_handle, temp, sizeof(temp), &bytesRead, nullptr)) {
        if (bytesRead > 0) {
            buffer.append(temp, static_cast<int>(bytesRead));
        }
    } else {
        DWORD err = GetLastError();
        if (err != ERROR_NO_DATA) { // 无数据不是错误
            emit errorOccurred(QStringLiteral("读取串口失败, 错误码: %1").arg(err));
            return -1;
        }
    }

    return static_cast<qint64>(bytesRead);
}

qint64 SerialPortAdapter::write(const QByteArray &data)
{
    if (!isOpen()) {
        return -1;
    }

    DWORD bytesWritten = 0;
    if (!WriteFile(m_handle, data.constData(),
                   static_cast<DWORD>(data.size()),
                   &bytesWritten, nullptr)) {
        DWORD err = GetLastError();
        emit errorOccurred(QStringLiteral("写入串口失败, 错误码: %1").arg(err));
        return -1;
    }

    return static_cast<qint64>(bytesWritten);
}

bool SerialPortAdapter::flush()
{
    if (!isOpen()) {
        return false;
    }
    return PurgeComm(m_handle, PURGE_RXCLEAR | PURGE_TXCLEAR) != 0;
}

void SerialPortAdapter::onReadReady()
{
    QByteArray buffer;
    if (read(buffer) > 0) {
        emit dataReceived(buffer);
    }
}

bool SerialPortAdapter::configurePort(quint32 baudRate)
{
    DCB dcb = {0};
    dcb.DCBlength = sizeof(DCB);

    if (!GetCommState(m_handle, &dcb)) {
        emit errorOccurred(QStringLiteral("获取串口状态失败"));
        return false;
    }

    // 配置参数: 8数据位, 1停止位, 无校验
    dcb.BaudRate = baudRate;
    dcb.ByteSize = 8;
    dcb.StopBits = ONESTOPBIT;
    dcb.Parity   = NOPARITY;
    dcb.fDtrControl = DTR_CONTROL_ENABLE;
    dcb.fRtsControl = RTS_CONTROL_ENABLE;

    if (!SetCommState(m_handle, &dcb)) {
        emit errorOccurred(QStringLiteral("设置串口参数失败"));
        return false;
    }

    // 设置输入/输出缓冲区大小
    SetupComm(m_handle, 4096, 4096);
    return true;
}

bool SerialPortAdapter::setTimeouts(DWORD readInterval)
{
    COMMTIMEOUTS timeouts = {0};
    timeouts.ReadIntervalTimeout         = readInterval;        // 字符间超时
    timeouts.ReadTotalTimeoutMultiplier  = 0;                    // 不累计
    timeouts.ReadTotalTimeoutConstant    = 0;                    // 无固定超时
    timeouts.WriteTotalTimeoutMultiplier = 0;
    timeouts.WriteTotalTimeoutConstant   = 0;

    return SetCommTimeouts(m_handle, &timeouts) != 0;
}
