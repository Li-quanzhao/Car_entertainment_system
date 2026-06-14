#ifndef BLUETOOTH_VIEWMODEL_H
#define BLUETOOTH_VIEWMODEL_H

#include <QObject>
#include <QVariantList>
#include <QTimer>

class BluetoothService;

class BluetoothViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectionChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY connectionChanged)
    Q_PROPERTY(bool discovering READ discovering NOTIFY discoveringChanged)

public:
    explicit BluetoothViewModel(BluetoothService *service, QObject *parent = nullptr);

    QVariantList devices() const { return m_devices; }
    bool connected() const { return m_connected; }
    QString deviceName() const { return m_deviceName; }
    bool discovering() const { return m_discovering; }

public slots:
    void startDiscovery();
    void connectToDevice(const QString &address, const QString &name);
    void disconnectDevice();
    void dial(const QString &number);
    void endCall();

signals:
    void devicesChanged();
    void connectionChanged();
    void discoveringChanged();
    void infoMessage(const QString &msg);
    void callStateChanged(const QString &state);

private:
    BluetoothService *m_service;
    QVariantList m_devices;
    bool m_connected = false;
    bool m_discovering = false;
    QString m_deviceName;
    QString m_connectedAddress;
};

#endif // BLUETOOTH_VIEWMODEL_H
