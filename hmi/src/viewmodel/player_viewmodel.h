#ifndef PLAYER_VIEWMODEL_H
#define PLAYER_VIEWMODEL_H

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QTimer>

class MediaService;

class PlayerViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString title READ title NOTIFY songChanged)
    Q_PROPERTY(QString artist READ artist NOTIFY songChanged)
    Q_PROPERTY(QString album READ album NOTIFY songChanged)
    Q_PROPERTY(int duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(int position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY stateChanged)
    Q_PROPERTY(QVariantList playlist READ playlist NOTIFY playlistChanged)

public:
    explicit PlayerViewModel(MediaService *mediaService, QObject *parent = nullptr);

    QString title() const { return m_title; }
    QString artist() const { return m_artist; }
    QString album() const { return m_album; }
    int duration() const { return m_duration; }
    int position() const { return m_position; }
    void setPosition(int pos);
    qreal volume() const { return m_volume; }
    void setVolume(qreal vol);
    bool playing() const { return m_playing; }
    QVariantList playlist() const { return m_playlist; }

public slots:
    void play();
    void pause();
    void next();
    void previous();
    void playIndex(int index);
    void loadPlaylist();

signals:
    void songChanged();
    void durationChanged(int duration);
    void positionChanged(int position);
    void volumeChanged(qreal volume);
    void stateChanged(bool playing);
    void playlistChanged();

private:
    void applySong(const QString &title, const QString &artist, int duration);

    MediaService *m_service;
    QString m_title;
    QString m_artist;
    QString m_album;
    int m_duration = 0;
    int m_position = 0;
    qreal m_volume = 0.5;
    bool m_playing = false;
    int m_currentIndex = -1;
    QVariantList m_playlist;
    QTimer *m_timer;
};

#endif // PLAYER_VIEWMODEL_H
