#ifndef MAP_SERVICE_H
#define MAP_SERVICE_H

#include <QObject>
#include <QVariantList>
#include "../infrastructure/database.h"

class MapService : public QObject
{
    Q_OBJECT

public:
    explicit MapService(Database *db, QObject *parent = nullptr);

    QVariantList searchPoi(const QString &query);
    QVariantList getFavorites();
    bool addFavorite(const QString &name, const QString &address,
                     double lat, double lon);

signals:
    void routeCalculated(const QVariantList &waypoints);

private:
    Database *m_db;
};

#endif // MAP_SERVICE_H
