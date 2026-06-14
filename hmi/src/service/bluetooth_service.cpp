#include "bluetooth_service.h"

BluetoothService::BluetoothService(BluetoothAdapter *adapter, Database *db,
                                   QObject *parent)
    : QObject(parent)
    , m_adapter(adapter)
    , m_db(db)
{
    connect(m_adapter, &BluetoothAdapter::deviceFound,
            this, &BluetoothService::deviceFound);
    connect(m_adapter, &BluetoothAdapter::discoveryFinished,
            this, &BluetoothService::discoveryFinished);
    connect(m_adapter, &BluetoothAdapter::connected, this, [this]() {
        emit connected(m_adapter->deviceName(), m_adapter->deviceAddress());
        emit connectionChanged(true);
    });
    connect(m_adapter, &BluetoothAdapter::disconnected, this, [this]() {
        emit disconnected();
        emit connectionChanged(false);
    });
    connect(m_adapter, &BluetoothAdapter::devicesUpdated,
            this, &BluetoothService::devicesUpdated);
    connect(m_adapter, &BluetoothAdapter::errorOccurred,
            this, &BluetoothService::errorOccurred);
}

QVariantList BluetoothService::getCallLogs()
{
    return m_db ? m_db->getCallLogs() : QVariantList();
}

void BluetoothService::startDiscovery()
{
    if (m_adapter)
        m_adapter->startDiscovery();
}

void BluetoothService::stopDiscovery()
{
    if (m_adapter)
        m_adapter->stopDiscovery();
}

void BluetoothService::connectToDevice(const QString &address, const QString &name)
{
    Q_UNUSED(name)
    if (m_adapter)
        m_adapter->connect(address);
}

void BluetoothService::disconnectDevice()
{
    if (m_adapter)
        m_adapter->disconnect();
}
