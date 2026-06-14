#ifndef BLUETOOTH_SERVICE_H
#define BLUETOOTH_SERVICE_H

#include <QObject>
#include <QVariantList>
#include "../infrastructure/database.h"
#include "../infrastructure/bluetooth_adapter.h"

class BluetoothService : public QObject
{
    Q_OBJECT

public:
    explicit BluetoothService(BluetoothAdapter *adapter, Database *db,
                              QObject *parent = nullptr);

    QVariantList getCallLogs();

public slots:
    void startDiscovery();
    void stopDiscovery();
    void connectToDevice(const QString &address, const QString &name);
    void disconnectDevice();

signals:
    void callLogsUpdated();
    void deviceFound(const QString &name, const QString &address);
    void discoveryFinished();
    void connected(const QString &name, const QString &address);
    void disconnected();
    void connectionChanged(bool connected);
    void devicesUpdated();
    void errorOccurred(const QString &error);

private:
    BluetoothAdapter *m_adapter;
    Database *m_db;
};

#endif // BLUETOOTH_SERVICE_H
