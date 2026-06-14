#include "map_service.h"
#include <QThread>

MapService::MapService(Database *db, QObject *parent)
    : QObject(parent)
    , m_db(db)
{
}

QVariantList MapService::searchPoi(const QString &query)
{
    if (query.trimmed().isEmpty())
        return QVariantList();

    QVariantList results;
    QString q = query.trimmed().toLower();

    // 1. 先搜索数据库中的收藏地点
    QVariantList favs = getFavorites();
    for (const auto &v : favs) {
        QVariantMap m = v.toMap();
        if (m["name"].toString().toLower().contains(q) ||
            m["address"].toString().toLower().contains(q)) {
            results.append(m);
        }
    }

    // 2. 搜索内置 POI 数据库
    struct POI { const char *name, *address; double lat, lon; };
    const POI builtin[] = {
        {"Shell Gas Station", "120 Main Street", 22.5431, 114.0579},
        {"Central Park Plaza", "50 Park Avenue", 22.5480, 114.0600},
        {"Sunshine Mall", "88 Sunny Road", 22.5550, 114.0680},
        {"City Hospital", "1 Health Lane", 22.5380, 114.0520},
        {"Grand Hotel", "200 Luxury Blvd", 22.5600, 114.0750},
        {"Tech Park", "5 Innovation Drive", 22.5450, 114.0450},
        {"Metro Station", "15 Transit Way", 22.5420, 114.0550},
        {"Public Library", "30 Reading Rd", 22.5500, 114.0500},
        {"Stadium", "100 Sports Ave", 22.5350, 114.0700},
        {"Airport Terminal", "1 Airport Blvd", 22.5100, 114.0000},
    };

    for (const auto &poi : builtin) {
        QString name = QString::fromUtf8(poi.name);
        QString addr = QString::fromUtf8(poi.address);
        if (name.toLower().contains(q) || addr.toLower().contains(q)) {
            QVariantMap m;
            m["name"] = name;
            m["address"] = addr;
            m["latitude"] = poi.lat;
            m["longitude"] = poi.lon;
            m["id"] = -1;
            results.append(m);
        }
    }

    return results;
}

QVariantList MapService::getFavorites()
{
    return m_db ? m_db->getFavoritePlaces() : QVariantList();
}

bool MapService::addFavorite(const QString &name, const QString &address,
                              double lat, double lon)
{
    if (!m_db) return false;
    QVariantMap place;
    place["name"] = name;
    place["address"] = address;
    place["latitude"] = lat;
    place["longitude"] = lon;
    return m_db->addFavoritePlace(place);
}
