#include "vehicle_service.h"

VehicleService::VehicleService(QObject *parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
{
    m_timer->setInterval(1000);
    connect(m_timer, &QTimer::timeout, this, &VehicleService::tick);
}

void VehicleService::startSimulation() { m_timer->start(); }
void VehicleService::stopSimulation()  { m_timer->stop(); }

void VehicleService::tick()
{
    auto *rng = QRandomGenerator::global();
    m_speed = qBound(0, m_speed + rng->bounded(-5, 8), 180);
    m_rpm   = qBound(800, m_rpm + rng->bounded(-200, 300), 7000);
    m_fuelLevel = qMax(0.0, m_fuelLevel - rng->generateDouble() * 0.001);
    if (m_speed > 0) m_mileage++;
    emit dataUpdated(m_speed, m_rpm, m_fuelLevel, m_mileage);
}
