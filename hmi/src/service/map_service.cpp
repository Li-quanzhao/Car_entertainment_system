#include "map_service.h"

MapService::MapService(Database *db, QObject *parent)
    : QObject(parent)
    , m_db(db)
{
}

QVariantList MapService::searchPoi(const QString &query)
{
    Q_UNUSED(query)
    return QVariantList();
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
