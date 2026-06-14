#ifndef VEHICLE_VIEWMODEL_H
#define VEHICLE_VIEWMODEL_H

#include <QObject>
#include <QTimer>

class VehicleService;

class VehicleViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int speed READ speed NOTIFY dataUpdated)
    Q_PROPERTY(int rpm READ rpm NOTIFY dataUpdated)
    Q_PROPERTY(qreal fuelLevel READ fuelLevel NOTIFY dataUpdated)
    Q_PROPERTY(int mileage READ mileage NOTIFY dataUpdated)
    Q_PROPERTY(double engineTemp READ engineTemp NOTIFY dataUpdated)
    Q_PROPERTY(bool doorOpen READ doorOpen NOTIFY dataUpdated)
    Q_PROPERTY(QString gear READ gear NOTIFY dataUpdated)

public:
    explicit VehicleViewModel(VehicleService *service, QObject *parent = nullptr);

    int speed() const { return m_speed; }
    int rpm() const { return m_rpm; }
    qreal fuelLevel() const { return m_fuelLevel; }
    int mileage() const { return m_mileage; }
    double engineTemp() const { return m_engineTemp; }
    bool doorOpen() const { return m_doorOpen; }
    QString gear() const { return m_gear; }

public slots:
    void startSimulation();
    void stopSimulation();

signals:
    void dataUpdated();

private:
    void updateGear();

    VehicleService *m_service;
    int m_speed = 0;
    int m_rpm = 0;
    qreal m_fuelLevel = 0.75;
    int m_mileage = 12345;
    double m_engineTemp = 90.0;
    bool m_doorOpen = false;
    QString m_gear = QStringLiteral("P");
};

#endif // VEHICLE_VIEWMODEL_H
