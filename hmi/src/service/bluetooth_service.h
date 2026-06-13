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

signals:
    void callLogsUpdated();

private:
    BluetoothAdapter *m_adapter;
    Database *m_db;
};

#endif // BLUETOOTH_SERVICE_H
