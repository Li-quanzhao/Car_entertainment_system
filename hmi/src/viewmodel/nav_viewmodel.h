#ifndef NAV_VIEWMODEL_H
#define NAV_VIEWMODEL_H

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

class NavViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString destination READ destination NOTIFY routeChanged)
    Q_PROPERTY(int etaMinutes READ etaMinutes NOTIFY routeChanged)
    Q_PROPERTY(double distanceKm READ distanceKm NOTIFY routeChanged)
    Q_PROPERTY(bool navigating READ navigating NOTIFY navigatingChanged)
    Q_PROPERTY(QVariantList poiResults READ poiResults NOTIFY poiResultsChanged)

public:
    explicit NavViewModel(QObject *parent = nullptr);

    QString destination() const { return m_destination; }
    int etaMinutes() const { return m_etaMinutes; }
    double distanceKm() const { return m_distanceKm; }
    bool navigating() const { return m_navigating; }
    QVariantList poiResults() const { return m_poiResults; }

public slots:
    void searchPoi(const QString &query);
    void navigateTo(const QString &name, double lat, double lon);
    void cancelNavigation();

signals:
    void routeChanged();
    void navigatingChanged();
    void poiResultsChanged();
    void infoMessage(const QString &msg);

private:
    QString m_destination;
    int m_etaMinutes = 0;
    double m_distanceKm = 0.0;
    bool m_navigating = false;
    QVariantList m_poiResults;
};

#endif // NAV_VIEWMODEL_H
