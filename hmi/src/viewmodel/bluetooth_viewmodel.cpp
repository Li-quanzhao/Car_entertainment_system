#include "bluetooth_viewmodel.h"
#include <QRandomGenerator>

BluetoothViewModel::BluetoothViewModel(QObject *parent)
    : QObject(parent)
{
}

void BluetoothViewModel::startDiscovery()
{
    if (m_discovering) return;
    m_discovering = true;
    emit discoveringChanged();
    emit infoMessage(QStringLiteral("正在扫描蓝牙设备..."));

    // 模拟扫描结果
    m_devices.clear();
    struct Device { const char *name; const char *addr; };
    const Device mock[] = {
        {"iPhone 15", "AA:BB:CC:DD:EE:01"},
        {"Galaxy S24", "AA:BB:CC:DD:EE:02"},
        {"Pixel 8", "AA:BB:CC:DD:EE:03"},
        {"AirPods Pro", "AA:BB:CC:DD:EE:04"},
        {"Car Audio", "AA:BB:CC:DD:EE:05"},
    };
    for (const auto &d : mock) {
        QVariantMap m;
        m["name"]    = QString::fromUtf8(d.name);
        m["address"] = QString::fromUtf8(d.addr);
        m_devices.append(m);
    }
    emit devicesChanged();
    emit infoMessage(QStringLiteral("找到 %1 个设备").arg(m_devices.size()));

    m_discovering = false;
    emit discoveringChanged();
}

void BluetoothViewModel::connectToDevice(const QString &address, const QString &name)
{
    m_connected = true;
    m_deviceName = name;
    m_connectedAddress = address;
    emit connectionChanged();
    emit infoMessage(QStringLiteral("已连接到 %1").arg(name));
}

void BluetoothViewModel::disconnectDevice()
{
    if (!m_connected) return;
    QString name = m_deviceName;
    m_connected = false;
    m_deviceName.clear();
    m_connectedAddress.clear();
    emit connectionChanged();
    emit infoMessage(QStringLiteral("已断开连接: %1").arg(name));
}

void BluetoothViewModel::dial(const QString &number)
{
    if (!m_connected) {
        emit infoMessage(QStringLiteral("未连接蓝牙设备"));
        return;
    }
    emit callStateChanged(QStringLiteral("dialing"));
    emit infoMessage(QStringLiteral("拨号: %1").arg(number));
}

void BluetoothViewModel::endCall()
{
    emit callStateChanged(QStringLiteral("idle"));
    emit infoMessage(QStringLiteral("通话已结束"));
}
