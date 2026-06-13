#ifndef BLUETOOTH_ADAPTER_H
#define BLUETOOTH_ADAPTER_H

#include <QObject>
#include <QTimer>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QThread>
#include <QMutex>
#include <QtConcurrent>

// winsock2.h 必须在 windows.h 之前包含
#include <winsock2.h>
#include <windows.h>
#include <bthdef.h>
#include <BluetoothAPIs.h>
#include <ws2bth.h>

/**
 * @brief Win32 Bluetooth API 封装
 *
 * 替代缺失的 QBluetooth，提供设备发现、连接、断开功能。
 * 使用 Win32 Bluetooth API (WSALookupService / BluetoothAuthenticateDevice)。
 *
 * CMake 需链接: Bthprops.lib Ws2_32.lib
 */
class BluetoothAdapter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectionChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY connectionChanged)
    Q_PROPERTY(QString deviceAddress READ deviceAddress NOTIFY connectionChanged)
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesUpdated)

public:
    explicit BluetoothAdapter(QObject *parent = nullptr);
    ~BluetoothAdapter() override;

    /// 开始扫描蓝牙设备
    void startDiscovery(int timeoutMs = 10000);
    /// 停止扫描
    void stopDiscovery();
    /// 是否正在扫描
    bool isDiscovering() const { QMutexLocker lock(&m_mutex); return m_discovering; }

    /// 连接到指定地址的设备 (格式: "00:11:22:33:44:55")
    bool connect(const QString &address);
    /// 断开当前连接
    void disconnect();
    /// 是否已连接
    bool isConnected() const { return m_connected; }
    /// 已连接设备名称
    QString deviceName() const { return m_deviceName; }
    /// 已连接设备地址
    QString deviceAddress() const { return m_deviceAddress; }
    /// 扫描到的设备列表
    QVariantList devices() const { return m_devices; }

signals:
    /// 发现新设备
    void deviceFound(const QString &name, const QString &address);
    /// 扫描完成
    void discoveryFinished();
    /// 已连接
    void connected();
    /// 已断开
    void disconnected();
    /// 连接状态变化
    void connectionChanged(bool connected);
    /// 设备列表更新
    void devicesUpdated();
    /// 错误
    void errorOccurred(const QString &error);

private:
    /// 将 BTH_ADDR 转为地址字符串 "XX:XX:XX:XX:XX:XX"
    static QString bthAddrToString(BTH_ADDR btha);
    /// 将地址字符串转为 BTH_ADDR
    static BTH_ADDR stringToBthAddr(const QString &addr);

    mutable QMutex m_mutex;
    bool m_discovering = false;
    bool m_connected   = false;
    QString m_deviceName;
    QString m_deviceAddress;
    QVariantList m_devices;

    QTimer *m_discoveryTimer;
    QThread *m_workerThread;
};

#endif // BLUETOOTH_ADAPTER_H
