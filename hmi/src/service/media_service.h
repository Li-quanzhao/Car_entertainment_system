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

    /// 设置当前播放列表（ViewModel 调用）
    void setPlaylist(const QVariantList &songs);
    QVariantList playlist() const { return m_playlist; }
    int currentIndex() const { return m_currentIndex; }

public slots:
    void playSong(const QString &path);
    void playIndex(int index);
    void togglePlayPause();
    void next();
    void previous();
    void setVolume(qreal vol);
    qreal volume() const { return m_audio->volume(); }

signals:
    void songChanged(const QString &title, const QString &artist, int duration);
    void stateChanged(bool playing);
    void progressChanged(int position);

private:
    AudioEngine *m_audio;
    Database    *m_db;
    QVariantList m_playlist;
    int m_currentIndex = -1;
};

#endif // MEDIA_SERVICE_H
