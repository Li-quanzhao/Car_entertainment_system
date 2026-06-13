#ifndef VEHICLE_SERVICE_H
#define VEHICLE_SERVICE_H

#include <QObject>
#include <QTimer>
#include <QRandomGenerator>

class VehicleService : public QObject
{
    Q_OBJECT

public:
    explicit VehicleService(QObject *parent = nullptr);

    int speed() const { return m_speed; }
    int rpm() const { return m_rpm; }
    qreal fuelLevel() const { return m_fuelLevel; }
    int mileage() const { return m_mileage; }

public slots:
    void startSimulation();
    void stopSimulation();

signals:
    void dataUpdated(int speed, int rpm, qreal fuel, int mileage);

private:
    void tick();
    QTimer *m_timer = nullptr;
    int m_speed = 0;
    int m_rpm = 0;
    qreal m_fuelLevel = 0.75;
    int m_mileage = 12345;
};

#endif // VEHICLE_SERVICE_H
