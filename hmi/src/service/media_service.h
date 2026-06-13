#ifndef MEDIA_SERVICE_H
#define MEDIA_SERVICE_H

#include <QObject>
#include <QVariantList>
#include "../infrastructure/audio_engine.h"
#include "../infrastructure/database.h"

class MediaService : public QObject
{
    Q_OBJECT

public:
    explicit MediaService(AudioEngine *audio, Database *db, QObject *parent = nullptr);

    QVariantList getAllSongs();
    QVariantList getPlaylist(int id);

public slots:
    void playSong(const QString &path);
    void playIndex(int index);
    void togglePlayPause();
    void next();
    void previous();

signals:
    void songChanged(const QString &title, const QString &artist, int duration);
    void stateChanged(bool playing);
    void progressChanged(int position);

private:
    AudioEngine *m_audio;
    Database    *m_db;
};

#endif // MEDIA_SERVICE_H
