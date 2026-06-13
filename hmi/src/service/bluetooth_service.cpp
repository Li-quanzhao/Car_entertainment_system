#include "bluetooth_service.h"

BluetoothService::BluetoothService(BluetoothAdapter *adapter, Database *db,
                                   QObject *parent)
    : QObject(parent)
    , m_adapter(adapter)
    , m_db(db)
{
}

QVariantList BluetoothService::getCallLogs()
{
    return m_db ? m_db->getCallLogs() : QVariantList();
}
