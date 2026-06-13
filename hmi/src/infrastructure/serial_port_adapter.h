#ifndef SERIAL_PORT_ADAPTER_H
#define SERIAL_PORT_ADAPTER_H

#include <QObject>
#include <QTimer>
#include <QByteArray>
#include <QString>
#include <windows.h>

/**
 * @brief Win32 API 串口通信封装
 *
 * 替代缺失的 QSerialPort，使用 Win32 API 实现串口读写。
 * CreateFile/SetCommState/ReadFile/WriteFile
 */
class SerialPortAdapter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool open READ isOpen NOTIFY connectionChanged)
    Q_PROPERTY(QString portName READ portName NOTIFY connectionChanged)

public:
    explicit SerialPortAdapter(QObject *parent = nullptr);
    ~SerialPortAdapter() override;

    /// 打开串口
    bool open(const QString &portName, quint32 baudRate = 115200);
    /// 关闭串口
    void close();
    /// 串口是否已打开
    bool isOpen() const { return m_handle != INVALID_HANDLE_VALUE; }
    /// 当前端口名
    QString portName() const { return m_portName; }

    /// 同步读取（非阻塞，立即返回当前缓冲区数据）
    qint64 read(QByteArray &buffer);
    /// 同步写入
    qint64 write(const QByteArray &data);

    /// 清空收发缓冲区
    bool flush();

signals:
    /// 收到数据（由定时器轮询触发）
    void dataReceived(const QByteArray &data);
    /// 发生错误
    void errorOccurred(const QString &error);
    /// 连接状态变化
    void connectionChanged(bool connected);

private slots:
    /// 定时轮询读取
    void onReadReady();

private:
    /// 配置串口参数（波特率、数据位、停止位、校验位）
    bool configurePort(quint32 baudRate);
    /// 设置超时
    bool setTimeouts(DWORD readInterval = 10);

    HANDLE  m_handle;         ///< 串口句柄
    QString m_portName;       ///< 端口名称（如 "COM3"）
    QTimer *m_readTimer;      ///< 读取轮询定时器
};

#endif // SERIAL_PORT_ADAPTER_H
