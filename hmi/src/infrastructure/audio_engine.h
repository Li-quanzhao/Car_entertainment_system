#ifndef AUDIO_ENGINE_H
#define AUDIO_ENGINE_H

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QUrl>

class AudioEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)

public:
    enum State { Stopped = 0, Playing, Paused };
    Q_ENUM(State)

    explicit AudioEngine(QObject *parent = nullptr);
    ~AudioEngine() override;

    State state() const { return m_player->playbackState() == QMediaPlayer::PlayingState ? Playing
                   : m_player->playbackState() == QMediaPlayer::PausedState ? Paused : Stopped; }
    qreal volume() const;
    void setVolume(qreal vol);
    qint64 position() const;
    void setPosition(qint64 pos);
    qint64 duration() const { return m_player->duration(); }
    QString source() const { return m_currentSource; }
    void setSource(const QString &url);

public slots:
    void play();
    void pause();
    void stop();

signals:
    void stateChanged(State state);
    void volumeChanged(qreal volume);
    void positionChanged(qint64 position);
    void durationChanged(qint64 duration);
    void sourceChanged(const QString &source);
    void errorOccurred(const QString &error);

private:
    QMediaPlayer  *m_player;
    QAudioOutput  *m_audioOutput;
    QString        m_currentSource;
};

#endif // AUDIO_ENGINE_H
