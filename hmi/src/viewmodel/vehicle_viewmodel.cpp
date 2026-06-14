#include "vehicle_viewmodel.h"
#include "../service/vehicle_service.h"

VehicleViewModel::VehicleViewModel(VehicleService *service, QObject *parent)
    : QObject(parent)
    , m_service(service)
{
    connect(m_service, &VehicleService::dataUpdated, this,
            [this](int speed, int rpm, qreal fuel, int mileage) {
        m_speed = speed;
        m_rpm = rpm;
        m_fuelLevel = fuel;
        m_mileage = mileage;
        updateGear();
        emit dataUpdated();
    });
}

void VehicleViewModel::startSimulation()
{
    m_service->startSimulation();
}

void VehicleViewModel::stopSimulation()
{
    m_service->stopSimulation();
}

void VehicleViewModel::updateGear()
{
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
}
