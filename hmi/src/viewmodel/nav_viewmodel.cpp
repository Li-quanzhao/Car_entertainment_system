#include "nav_viewmodel.h"
#include "../service/map_service.h"
#include <QRandomGenerator>

NavViewModel::NavViewModel(MapService *mapService, QObject *parent)
    : QObject(parent)
    , m_mapService(mapService)
{
}

void NavViewModel::searchPoi(const QString &query)
{
    m_poiResults = m_mapService->searchPoi(query);
    emit poiResultsChanged();
    if (m_poiResults.isEmpty()) {
        emit infoMessage(QStringLiteral("未找到匹配的结果: %1").arg(query));
    } else {
        emit infoMessage(QStringLiteral("找到 %1 个结果").arg(m_poiResults.size()));
    }
}

void NavViewModel::navigateTo(const QString &name, double lat, double lon)
{
    Q_UNUSED(lat)
    Q_UNUSED(lon)
    m_destination = name;
    m_distanceKm = QRandomGenerator::global()->bounded(3, 25);
    m_etaMinutes = static_cast<int>(m_distanceKm / 0.5);
    m_navigating = true;
    emit routeChanged();
    emit navigatingChanged();
    emit infoMessage(QStringLiteral("导航到 %1，距离 %2 km，预计 %3 分钟")
                     .arg(name).arg(m_distanceKm, 0, 'f', 1).arg(m_etaMinutes));
}

void NavViewModel::cancelNavigation()
{
    m_navigating = false;
    m_destination.clear();
    emit routeChanged();
    emit navigatingChanged();
    emit infoMessage(QStringLiteral("导航已取消"));
}
