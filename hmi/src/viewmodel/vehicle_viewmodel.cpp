#include "vehicle_viewmodel.h"
#include <QRandomGenerator>

VehicleViewModel::VehicleViewModel(QObject *parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
{
    m_timer->setInterval(1000);
    connect(m_timer, &QTimer::timeout, this, &VehicleViewModel::simulate);
}

void VehicleViewModel::startSimulation()
{
    m_timer->start();
}

void VehicleViewModel::stopSimulation()
{
    m_timer->stop();
}

void VehicleViewModel::simulate()
{
    auto *rng = QRandomGenerator::global();

    m_speed = qBound(0, m_speed + rng->bounded(-5, 8), 180);
    m_rpm   = qBound(800, m_rpm + rng->bounded(-200, 300), 7000);
    m_fuelLevel = qMax(0.0, m_fuelLevel - rng->generateDouble() * 0.002);

    if (m_speed == 0) {
        m_gear = QStringLiteral("P");
    } else if (m_speed < 30) {
        m_gear = QStringLiteral("1");
    } else if (m_speed < 60) {
        m_gear = QStringLiteral("2");
    } else if (m_speed < 100) {
        m_gear = QStringLiteral("3");
    } else {
        m_gear = QStringLiteral("D");
    }

    m_engineTemp = 85.0 + rng->generateDouble() * 10.0;
    m_doorOpen = rng->bounded(20) == 0;
    if (m_speed > 0) m_mileage++;

    emit dataUpdated();
}
