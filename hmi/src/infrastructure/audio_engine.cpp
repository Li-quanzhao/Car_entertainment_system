#include "audio_engine.h"

AudioEngine::AudioEngine(QObject *parent)
    : QObject(parent)
    , m_player(new QMediaPlayer(this))
    , m_audioOutput(new QAudioOutput(this))
{
    m_player->setAudioOutput(m_audioOutput);
    m_audioOutput->setVolume(0.5);

    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this]() {
        emit stateChanged(state());
    });
    connect(m_player, &QMediaPlayer::positionChanged, this, &AudioEngine::positionChanged);
    connect(m_player, &QMediaPlayer::durationChanged, this, &AudioEngine::durationChanged);
    connect(m_player, &QMediaPlayer::sourceChanged, this, [this]() {
        emit sourceChanged(m_player->source().toString());
    });
    connect(m_player, &QMediaPlayer::errorOccurred, this, [this](QMediaPlayer::Error err) {
        if (err != QMediaPlayer::NoError)
            emit errorOccurred(m_player->errorString());
    });
    connect(m_audioOutput, &QAudioOutput::volumeChanged, this, &AudioEngine::volumeChanged);
}

AudioEngine::~AudioEngine() = default;

qreal AudioEngine::volume() const { return m_audioOutput->volume(); }

void AudioEngine::setVolume(qreal vol)
{
    if (vol < 0.0) vol = 0.0;
    if (vol > 1.0) vol = 1.0;
    m_audioOutput->setVolume(vol);
}

qint64 AudioEngine::position() const { return m_player->position(); }

void AudioEngine::setPosition(qint64 pos) { m_player->setPosition(pos); }

void AudioEngine::setSource(const QString &url)
{
    if (m_currentSource != url) {
        m_currentSource = url;
        m_player->setSource(QUrl::fromLocalFile(url));
    }
}

void AudioEngine::play() { m_player->play(); }
void AudioEngine::pause() { m_player->pause(); }
void AudioEngine::stop() { m_player->stop(); }
