#ifndef DATABASE_H
#define DATABASE_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QVariantList>
#include <QVariantMap>

class Database : public QObject
{
    Q_OBJECT

public:
    explicit Database(QObject *parent = nullptr);
    ~Database() override;

    bool initialize(const QString &dbPath = QString());

    // 音乐库操作
    bool addSong(const QVariantMap &song);
    QVariantList getAllSongs() const;
    bool removeSong(int id);

    // 播放列表操作
    int  createPlaylist(const QString &name);
    bool addToPlaylist(int playlistId, int songId);
    QVariantList getPlaylistSongs(int playlistId) const;

    // 最近播放
    bool addRecentPlay(int songId);
    QVariantList getRecentPlays(int limit = 20) const;

    // 收藏地点 (POI)
    bool addFavoritePlace(const QVariantMap &place);
    QVariantList getFavoritePlaces() const;

    // 通话记录
    bool addCallLog(const QVariantMap &call);
    QVariantList getCallLogs(int limit = 50) const;

signals:
    void databaseError(const QString &error);

private:
    bool createTables();
    QSqlDatabase m_db;
    QString m_dbPath;
};

#endif // DATABASE_H
