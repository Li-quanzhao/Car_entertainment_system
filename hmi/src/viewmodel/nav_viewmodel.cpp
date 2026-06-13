#include "nav_viewmodel.h"
#include <QRandomGenerator>

NavViewModel::NavViewModel(QObject *parent)
    : QObject(parent)
{
}

void NavViewModel::searchPoi(const QString &query)
{
    m_poiResults.clear();

    struct POI { const char *name; double lat, lon; };
    const POI all[] = {
        {"Shell Gas Station", 22.5431, 114.0579},
        {"Central Park Plaza", 22.5480, 114.0600},
        {"Sunshine Mall", 22.5550, 114.0680},
        {"City Hospital", 22.5380, 114.0520},
        {"Grand Hotel", 22.5600, 114.0750},
        {"Tech Park", 22.5450, 114.0450},
    };

    QString q = query.toLower();
    for (const auto &poi : all) {
        QString name = QString::fromUtf8(poi.name);
        if (name.toLower().contains(q)) {
            QVariantMap m;
            m["name"]      = name;
            m["latitude"]  = poi.lat;
            m["longitude"] = poi.lon;
            m_poiResults.append(m);
        }
    }

    emit poiResultsChanged();
    if (m_poiResults.isEmpty()) {
        emit infoMessage(QStringLiteral("未找到匹配的结果: %1").arg(query));
    } else {
        emit infoMessage(QStringLiteral("找到 %1 个结果").arg(m_poiResults.size()));
    }
}

void NavViewModel::navigateTo(const QString &name, double lat, double lon)
{
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
