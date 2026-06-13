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

void MediaService::playIndex(int index)
{
    Q_UNUSED(index)
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
    Q_UNUSED(this)
}

void MediaService::previous()
{
    Q_UNUSED(this)
}
