#include "bluetooth_adapter.h"
#include <QDebug>
#include <QMutexLocker>

BluetoothAdapter::BluetoothAdapter(QObject *parent)
    : QObject(parent)
    , m_discoveryTimer(new QTimer(this))
    , m_workerThread(new QThread(this))
{
    WSADATA wsaData;
    WSAStartup(MAKEWORD(2, 2), &wsaData);

    m_discoveryTimer->setSingleShot(true);
    QObject::connect(m_discoveryTimer, &QTimer::timeout,
                     this, &BluetoothAdapter::stopDiscovery);
}

BluetoothAdapter::~BluetoothAdapter()
{
    stopDiscovery();
    disconnect();
    m_workerThread->quit();
    m_workerThread->wait(3000);
    WSACleanup();
}

// ============================================================
// 设备发现
// ============================================================

void BluetoothAdapter::startDiscovery(int timeoutMs)
{
    QMutexLocker lock(&m_mutex);
    if (m_discovering) {
        return;
    }
    m_discovering = true;
    m_devices.clear();
    lock.unlock();

    emit devicesUpdated();

    // 在后台线程中执行耗时的蓝牙扫描
    QtConcurrent::run([this, timeoutMs]() {
        QMutexLocker lock(&m_mutex);

        // 1. 查找本地蓝牙无线电
        BLUETOOTH_FIND_RADIO_PARAMS radioParams = {
            sizeof(BLUETOOTH_FIND_RADIO_PARAMS)
        };
        HANDLE radioHandle = nullptr;
        HBLUETOOTH_RADIO_FIND radioFind =
            BluetoothFindFirstRadio(&radioParams, &radioHandle);

        if (radioFind == nullptr) {
            lock.unlock();
            QMetaObject::invokeMethod(this, [this]() {
                emit errorOccurred(QStringLiteral("未找到蓝牙适配器"));
                m_discovering = false;
            });
            return;
        }

        // 2. 遍历所有无线电设备
        do {
            BLUETOOTH_RADIO_INFO radioInfo = {
                sizeof(BLUETOOTH_RADIO_INFO)
            };
            BluetoothGetRadioInfo(radioHandle, &radioInfo);

            // 3. 执行 SDP 查询来发现设备
            WSAQUERYSETW querySet = {0};
            querySet.dwSize      = sizeof(WSAQUERYSETW);
            querySet.dwNameSpace = NS_BTH;

            HANDLE lookupHandle = nullptr;
            DWORD  flags        = LUP_CONTAINERS | LUP_RETURN_NAME
                                  | LUP_RETURN_ADDR | LUP_FLUSHCACHE;

            if (WSALookupServiceBeginW(&querySet, flags,
                                       &lookupHandle) == SOCKET_ERROR) {
                continue;
            }

            // 4. 枚举发现的设备
            bool queryDone = false;
            while (!queryDone) {
                BYTE buffer[4096];
                LPWSAQUERYSETW pResults =
                    reinterpret_cast<LPWSAQUERYSETW>(buffer);
                pResults->dwSize = sizeof(buffer);
                DWORD bufferSize = sizeof(buffer);

                int result = WSALookupServiceNextW(
                    lookupHandle, flags, &bufferSize, pResults);

                if (result == SOCKET_ERROR) {
                    int wsaErr = WSAGetLastError();
                    if (wsaErr == WSA_E_NO_MORE || wsaErr == WSAENOMORE) {
                        queryDone = true;
                    } else if (wsaErr == WSAEFAULT) {
                        continue;
                    } else {
                        queryDone = true;
                    }
                    continue;
                }

                QString deviceName;
                if (pResults->lpszServiceInstanceName) {
                    deviceName = QString::fromWCharArray(
                        pResults->lpszServiceInstanceName);
                }

                BTH_ADDR btha = 0;
                if (pResults->lpcsaBuffer &&
                    pResults->lpcsaBuffer->RemoteAddr.lpSockaddr) {
                    SOCKADDR_BTH *sockAddr =
                        reinterpret_cast<SOCKADDR_BTH *>(
                            pResults->lpcsaBuffer->RemoteAddr.lpSockaddr);
                    btha = sockAddr->btAddr;
                }

                QString addrStr = bthAddrToString(btha);

                if (!deviceName.isEmpty() && !addrStr.isEmpty()) {
                    QString nameCopy = deviceName;
                    QString addrCopy = addrStr;
                    QMetaObject::invokeMethod(this, [this, nameCopy, addrCopy]() {
                        // 去重
                        for (const auto &dev : m_devices) {
                            QVariantMap map = dev.toMap();
                            if (map["address"].toString() == addrCopy) {
                                return;
                            }
                        }
                        QVariantMap device;
                        device["name"]    = nameCopy;
                        device["address"] = addrCopy;
                        m_devices.append(device);
                        emit devicesUpdated();
                        emit deviceFound(nameCopy, addrCopy);
                    });
                }
            }
            WSALookupServiceEnd(lookupHandle);

        } while (BluetoothFindNextRadio(radioFind, &radioHandle));

        BluetoothFindRadioClose(radioFind);
        CloseHandle(radioHandle);

        lock.unlock();
        QMetaObject::invokeMethod(this, [this]() {
            m_discovering = false;
            emit discoveryFinished();
        });
    });

    m_discoveryTimer->start(timeoutMs);
}

void BluetoothAdapter::stopDiscovery()
{
    QMutexLocker lock(&m_mutex);
    if (!m_discovering) {
        return;
    }
    m_discovering = false;
    lock.unlock();

    m_discoveryTimer->stop();
    emit discoveryFinished();
}

// ============================================================
// 连接管理
// ============================================================

bool BluetoothAdapter::connect(const QString &address)
{
    if (m_connected) {
        disconnect();
    }

    BTH_ADDR targetAddr = stringToBthAddr(address);
    if (targetAddr == 0) {
        emit errorOccurred(QStringLiteral("无效的蓝牙地址: %1").arg(address));
        return false;
    }

    SOCKADDR_BTH sa = {0};
    sa.addressFamily  = AF_BTH;
    sa.btAddr         = targetAddr;
    sa.serviceClassId = RFCOMM_PROTOCOL_UUID;
    sa.port           = 0;

    SOCKET s = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
    if (s == INVALID_SOCKET) {
        emit errorOccurred(
            QStringLiteral("创建蓝牙 socket 失败, 错误码: %1")
                .arg(WSAGetLastError()));
        return false;
    }

    DWORD timeout = 10000;
    setsockopt(s, SOL_SOCKET, SO_RCVTIMEO,
               reinterpret_cast<const char *>(&timeout), sizeof(timeout));
    setsockopt(s, SOL_SOCKET, SO_SNDTIMEO,
               reinterpret_cast<const char *>(&timeout), sizeof(timeout));

    int result = ::connect(s,
                           reinterpret_cast<struct sockaddr *>(&sa),
                           sizeof(sa));
    if (result == SOCKET_ERROR) {
        int err = WSAGetLastError();
        closesocket(s);
        emit errorOccurred(
            QStringLiteral("蓝牙连接失败: %1 (错误码: %2)")
                .arg(address).arg(err));
        return false;
    }

    m_connected    = true;
    m_deviceAddress = address;
    m_deviceName.clear();
    for (const auto &dev : m_devices) {
        QVariantMap map = dev.toMap();
        if (map["address"].toString() == address) {
            m_deviceName = map["name"].toString();
            break;
        }
    }
    if (m_deviceName.isEmpty()) {
        m_deviceName = address;
    }

    closesocket(s);

    emit connectionChanged(true);
    emit connected();
    qDebug() << "蓝牙已连接:" << m_deviceName << address;
    return true;
}

void BluetoothAdapter::disconnect()
{
    if (!m_connected) {
        return;
    }

    m_connected    = false;
    m_deviceName.clear();
    m_deviceAddress.clear();

    emit connectionChanged(false);
    emit disconnected();
    qDebug() << "蓝牙已断开";
}

// ============================================================
// 工具函数
// ============================================================

QString BluetoothAdapter::bthAddrToString(BTH_ADDR btha)
{
    return QStringLiteral("%1:%2:%3:%4:%5:%6")
        .arg(static_cast<quint8>((btha >> 40) & 0xFF), 2, 16, QChar('0'))
        .arg(static_cast<quint8>((btha >> 32) & 0xFF), 2, 16, QChar('0'))
        .arg(static_cast<quint8>((btha >> 24) & 0xFF), 2, 16, QChar('0'))
        .arg(static_cast<quint8>((btha >> 16) & 0xFF), 2, 16, QChar('0'))
        .arg(static_cast<quint8>((btha >> 8) & 0xFF), 2, 16, QChar('0'))
        .arg(static_cast<quint8>(btha & 0xFF), 2, 16, QChar('0'))
        .toUpper();
}

BTH_ADDR BluetoothAdapter::stringToBthAddr(const QString &addr)
{
    QStringList parts = addr.split(':');
    if (parts.size() != 6) {
        return 0;
    }

    BTH_ADDR result = 0;
    for (int i = 0; i < 6; ++i) {
        bool ok = false;
        quint8 byte = static_cast<quint8>(parts[i].toUInt(&ok, 16));
        if (!ok) {
            return 0;
        }
        result = (result << 8) | byte;
    }
    return result;
}
