#include "player_viewmodel.h"
#include "../service/media_service.h"

PlayerViewModel::PlayerViewModel(MediaService *mediaService, QObject *parent)
    : QObject(parent)
    , m_service(mediaService)
    , m_timer(new QTimer(this))
{
    m_timer->setInterval(500);
    connect(m_timer, &QTimer::timeout, this, [this]() {
        if (m_playing) {
            m_position += 500;
            if (m_position >= m_duration && m_duration > 0) {
                next();
            }
            emit positionChanged(m_position);
        }
    });

    // 监听 MediaService 信号同步状态
    connect(m_service, &MediaService::songChanged, this,
            [this](const QString &title, const QString &artist, int duration) {
        applySong(title, artist, duration);
        m_timer->start();
        m_playing = true;
        emit stateChanged(true);
    });

    connect(m_service, &MediaService::stateChanged, this,
            [this](bool playing) {
        m_playing = playing;
        if (playing) m_timer->start();
        else m_timer->stop();
        emit stateChanged(playing);
    });

    connect(m_service, &MediaService::progressChanged, this,
            [this](int position) {
        m_position = position;
        emit positionChanged(position);
    });
}

void PlayerViewModel::setPosition(int pos)
{
    m_position = qBound(0, pos, m_duration);
    emit positionChanged(m_position);
}

void PlayerViewModel::setVolume(qreal vol)
{
    m_volume = qBound(0.0, vol, 1.0);
    m_service->setVolume(m_volume);
    emit volumeChanged(m_volume);
}

void PlayerViewModel::play()
{
    if (m_playlist.isEmpty()) return;
    if (m_currentIndex < 0) m_currentIndex = 0;
    m_service->setPlaylist(m_playlist);
    m_service->playIndex(m_currentIndex);
}

void PlayerViewModel::pause()
{
    m_playing = false;
    m_timer->stop();
    m_service->togglePlayPause();
    emit stateChanged(false);
}

void PlayerViewModel::next()
{
    if (m_playlist.isEmpty()) return;
    m_currentIndex = (m_currentIndex + 1) % m_playlist.size();
    m_service->setPlaylist(m_playlist);
    m_service->playIndex(m_currentIndex);
}

void PlayerViewModel::previous()
{
    if (m_playlist.isEmpty()) return;
    m_currentIndex = (m_currentIndex - 1 + m_playlist.size()) % m_playlist.size();
    m_service->setPlaylist(m_playlist);
    m_service->playIndex(m_currentIndex);
}

void PlayerViewModel::playIndex(int index)
{
    if (index < 0 || index >= m_playlist.size()) return;
    m_currentIndex = index;
    QVariantMap song = m_playlist[index].toMap();
    applySong(song["title"].toString(),
              song["artist"].toString(),
              song["duration"].toInt());
    m_service->setPlaylist(m_playlist);
    m_service->playIndex(index);
}

void PlayerViewModel::loadPlaylist()
{
    QVariantList songs = m_service->getAllSongs();
    if (songs.isEmpty()) {
        // 数据库为空时加载演示歌曲
        struct Demo { const char *title, *artist; int sec; };
        const Demo demos[] = {
            {"Highway to Heaven", "Car Band", 240},
            {"Midnight Drive", "Electronic Dreams", 195},
            {"Road Trip", "The Travelers", 210},
            {"City Lights", "Urban Groove", 180},
            {"Sunset Boulevard", "Cruise Control", 225},
        };
        m_playlist.clear();
        for (const auto &d : demos) {
            QVariantMap m;
            m["title"]    = QString::fromUtf8(d.title);
            m["artist"]   = QString::fromUtf8(d.artist);
            m["duration"] = d.sec * 1000;
            m_playlist.append(m);
        }
    } else {
        m_playlist = songs;
    }
    m_currentIndex = -1;
    emit playlistChanged();
}

void PlayerViewModel::applySong(const QString &title, const QString &artist, int duration)
{
    m_title = title;
    m_artist = artist;
    m_duration = duration;
    m_position = 0;
    emit songChanged();
    emit durationChanged(duration);
    emit positionChanged(0);
}
