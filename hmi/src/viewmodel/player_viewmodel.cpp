#include "player_viewmodel.h"

PlayerViewModel::PlayerViewModel(QObject *parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
{
    m_timer->setInterval(500);
    connect(m_timer, &QTimer::timeout, this, [this]() {
        if (m_playing) {
            m_position += 500;
            if (m_position >= m_duration) {
                next();
            }
            emit positionChanged(m_position);
        }
    });
    loadDemoSongs();
}

void PlayerViewModel::setPosition(int pos)
{
    m_position = qBound(0, pos, m_duration);
    emit positionChanged(m_position);
}

void PlayerViewModel::setVolume(qreal vol)
{
    m_volume = qBound(0.0, vol, 1.0);
    emit volumeChanged(m_volume);
}

void PlayerViewModel::play()
{
    if (m_playlist.isEmpty()) return;
    if (m_currentIndex < 0) m_currentIndex = 0;
    m_playing = true;
    m_timer->start();
    emit stateChanged(true);
}

void PlayerViewModel::pause()
{
    m_playing = false;
    m_timer->stop();
    emit stateChanged(false);
}

void PlayerViewModel::next()
{
    if (m_playlist.isEmpty()) return;
    m_currentIndex = (m_currentIndex + 1) % m_playlist.size();
    playIndex(m_currentIndex);
}

void PlayerViewModel::previous()
{
    if (m_playlist.isEmpty()) return;
    m_currentIndex = (m_currentIndex - 1 + m_playlist.size()) % m_playlist.size();
    playIndex(m_currentIndex);
}

void PlayerViewModel::playIndex(int index)
{
    if (index < 0 || index >= m_playlist.size()) return;
    m_currentIndex = index;
    QVariantMap song = m_playlist[index].toMap();
    m_title = song["title"].toString();
    m_artist = song["artist"].toString();
    m_duration = song["duration"].toInt();
    m_position = 0;
    emit songChanged();
    emit durationChanged(m_duration);
    emit positionChanged(0);
    play();
}

void PlayerViewModel::loadDemoSongs()
{
    struct Demo { const char *title, *artist; int sec; };
    const Demo songs[] = {
        {"Highway to Heaven", "Car Band", 240},
        {"Midnight Drive", "Electronic Dreams", 195},
        {"Road Trip", "The Travelers", 210},
        {"City Lights", "Urban Groove", 180},
        {"Sunset Boulevard", "Cruise Control", 225},
    };
    m_playlist.clear();
    for (const auto &s : songs) {
        QVariantMap m;
        m["title"]    = QString::fromUtf8(s.title);
        m["artist"]   = QString::fromUtf8(s.artist);
        m["duration"] = s.sec * 1000;
        m_playlist.append(m);
    }
    emit playlistChanged();
}
