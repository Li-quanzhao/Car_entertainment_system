#include "media_service.h"

MediaService::MediaService(AudioEngine *audio, Database *db, QObject *parent)
    : QObject(parent)
    , m_audio(audio)
    , m_db(db)
{
    connect(m_audio, &AudioEngine::stateChanged, this, &MediaService::stateChanged);
    connect(m_audio, &AudioEngine::positionChanged, this, &MediaService::progressChanged);
}

QVariantList MediaService::getAllSongs()
{
    return m_db ? m_db->getAllSongs() : QVariantList();
}

QVariantList MediaService::getPlaylist(int id)
{
    return m_db ? m_db->getPlaylistSongs(id) : QVariantList();
}

void MediaService::playSong(const QString &path)
{
    m_audio->setSource(path);
    m_audio->play();
}

void MediaService::setPlaylist(const QVariantList &songs)
{
    m_playlist = songs;
    m_currentIndex = -1;
}

void MediaService::playIndex(int index)
{
    if (index < 0 || index >= m_playlist.size()) return;
    m_currentIndex = index;
    QVariantMap song = m_playlist[index].toMap();
    QString path = song["file_path"].toString();
    if (!path.isEmpty()) {
        m_audio->setSource(path);
        m_audio->play();
    } else {
        // 无文件路径时仍发出信号（UI 展示歌曲信息）
        m_audio->play();
    }
    emit songChanged(song["title"].toString(),
                     song["artist"].toString(),
                     song["duration"].toInt());
}

void MediaService::togglePlayPause()
{
    if (m_audio->state() == AudioEngine::Playing)
        m_audio->pause();
    else
        m_audio->play();
}

void MediaService::next()
{
    if (m_playlist.isEmpty()) return;
    int idx = (m_currentIndex + 1) % m_playlist.size();
    playIndex(idx);
}

void MediaService::previous()
{
    if (m_playlist.isEmpty()) return;
    int idx = (m_currentIndex - 1 + m_playlist.size()) % m_playlist.size();
    playIndex(idx);
}

void MediaService::setVolume(qreal vol)
{
    m_audio->setVolume(vol);
}
