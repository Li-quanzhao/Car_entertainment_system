#include "bluetooth_viewmodel.h"
#include "../service/bluetooth_service.h"

BluetoothViewModel::BluetoothViewModel(BluetoothService *service, QObject *parent)
    : QObject(parent)
    , m_service(service)
{
    connect(m_service, &BluetoothService::deviceFound, this,
            [this](const QString &name, const QString &address) {
        QVariantMap m;
        m["name"] = name;
        m["address"] = address;
        m_devices.append(m);
        emit devicesChanged();
        emit infoMessage(QStringLiteral("发现设备: %1").arg(name));
    });

    connect(m_service, &BluetoothService::discoveryFinished, this, [this]() {
        m_discovering = false;
        emit discoveringChanged();
        emit infoMessage(QStringLiteral("扫描完成，找到 %1 个设备").arg(m_devices.size()));
    });

    connect(m_service, &BluetoothService::connected, this,
            [this](const QString &name, const QString &address) {
        m_connected = true;
        m_deviceName = name;
        m_connectedAddress = address;
        emit connectionChanged();
        emit infoMessage(QStringLiteral("已连接到 %1").arg(name));
    });

    connect(m_service, &BluetoothService::disconnected, this, [this]() {
        if (!m_connected) return;
        QString oldName = m_deviceName;
        m_connected = false;
        m_deviceName.clear();
        m_connectedAddress.clear();
        emit connectionChanged();
        emit infoMessage(QStringLiteral("已断开: %1").arg(oldName));
    });

    connect(m_service, &BluetoothService::errorOccurred, this,
            [this](const QString &error) {
        emit infoMessage(error);
    });
}

void BluetoothViewModel::startDiscovery()
{
    if (m_discovering) return;
    m_discovering = true;
    m_devices.clear();
    emit devicesChanged();
    emit discoveringChanged();
    emit infoMessage(QStringLiteral("正在扫描蓝牙设备..."));
    m_service->startDiscovery();
}

void BluetoothViewModel::connectToDevice(const QString &address, const QString &name)
{
    m_service->connectToDevice(address, name);
}

void BluetoothViewModel::disconnectDevice()
{
    if (!m_connected) return;
    m_service->disconnectDevice();
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
