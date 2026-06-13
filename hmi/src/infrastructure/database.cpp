#include "database.h"
#include <QSqlError>
#include <QSqlQuery>
#include <QDir>
#include <QStandardPaths>
#include <QDateTime>

Database::Database(QObject *parent)
    : QObject(parent)
{
}

Database::~Database()
{
    if (m_db.isOpen()) {
        m_db.close();
    }
}

bool Database::initialize(const QString &dbPath)
{
    m_dbPath = dbPath;
    if (m_dbPath.isEmpty()) {
        QString appDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        QDir().mkpath(appDir);
        m_dbPath = appDir + QStringLiteral("/car_hmi.db");
    }

    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QStringLiteral("car_hmi_conn"));
    m_db.setDatabaseName(m_dbPath);

    if (!m_db.open()) {
        emit databaseError(QStringLiteral("打开数据库失败: %1").arg(m_db.lastError().text()));
        return false;
    }

    return createTables();
}

bool Database::createTables()
{
    QSqlQuery query(m_db);

    const QStringList stmts = {
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS songs ("
            "  id        INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  title     TEXT NOT NULL,"
            "  artist    TEXT DEFAULT '',"
            "  album     TEXT DEFAULT '',"
            "  duration  INTEGER DEFAULT 0,"
            "  file_path TEXT UNIQUE NOT NULL"
            ")"
        ),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS playlists ("
            "  id   INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  name TEXT NOT NULL"
            ")"
        ),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS playlist_songs ("
            "  playlist_id INTEGER,"
            "  song_id     INTEGER,"
            "  sort_order  INTEGER DEFAULT 0,"
            "  FOREIGN KEY(playlist_id) REFERENCES playlists(id),"
            "  FOREIGN KEY(song_id) REFERENCES songs(id)"
            ")"
        ),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS recent_plays ("
            "  id       INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  song_id  INTEGER,"
            "  played_at TEXT DEFAULT (datetime('now','localtime')),"
            "  FOREIGN KEY(song_id) REFERENCES songs(id)"
            ")"
        ),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS favorite_places ("
            "  id        INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  name      TEXT NOT NULL,"
            "  address   TEXT DEFAULT '',"
            "  latitude  REAL,"
            "  longitude REAL"
            ")"
        ),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS call_logs ("
            "  id         INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  contact    TEXT NOT NULL,"
            "  phone      TEXT,"
            "  direction  TEXT CHECK(direction IN ('incoming','outgoing','missed')),"
            "  duration   INTEGER DEFAULT 0,"
            "  called_at  TEXT DEFAULT (datetime('now','localtime'))"
            ")"
        )
    };

    for (const auto &sql : stmts) {
        if (!query.exec(sql)) {
            emit databaseError(QStringLiteral("建表失败: %1").arg(query.lastError().text()));
            return false;
        }
    }
    return true;
}

// --- Songs ---
bool Database::addSong(const QVariantMap &song)
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT OR IGNORE INTO songs(title, artist, album, duration, file_path) "
        "VALUES(:title, :artist, :album, :duration, :path)"));
    query.bindValue(":title", song["title"].toString());
    query.bindValue(":artist", song["artist"].toString());
    query.bindValue(":album", song["album"].toString());
    query.bindValue(":duration", song["duration"].toInt());
    query.bindValue(":path", song["file_path"].toString());
    if (!query.exec()) {
        emit databaseError(query.lastError().text());
        return false;
    }
    return true;
}

QVariantList Database::getAllSongs() const
{
    QVariantList list;
    QSqlQuery query(m_db);
    query.exec(QStringLiteral("SELECT * FROM songs ORDER BY title"));
    while (query.next()) {
        QVariantMap m;
        m["id"] = query.value("id");
        m["title"] = query.value("title");
        m["artist"] = query.value("artist");
        m["album"] = query.value("album");
        m["duration"] = query.value("duration");
        m["file_path"] = query.value("file_path");
        list.append(m);
    }
    return list;
}

bool Database::removeSong(int id)
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral("DELETE FROM songs WHERE id = ?"));
    query.addBindValue(id);
    return query.exec();
}

// --- Playlists ---
int Database::createPlaylist(const QString &name)
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral("INSERT INTO playlists(name) VALUES(?)"));
    query.addBindValue(name);
    if (!query.exec()) return -1;
    return query.lastInsertId().toInt();
}

bool Database::addToPlaylist(int playlistId, int songId)
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO playlist_songs(playlist_id, song_id) VALUES(?, ?)"));
    query.addBindValue(playlistId);
    query.addBindValue(songId);
    return query.exec();
}

QVariantList Database::getPlaylistSongs(int playlistId) const
{
    QVariantList list;
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT s.* FROM songs s "
        "JOIN playlist_songs ps ON s.id = ps.song_id "
        "WHERE ps.playlist_id = ? ORDER BY ps.sort_order"));
    query.addBindValue(playlistId);
    query.exec();
    while (query.next()) {
        QVariantMap m;
        m["id"] = query.value("id");
        m["title"] = query.value("title");
        m["artist"] = query.value("artist");
        m["album"] = query.value("album");
        m["duration"] = query.value("duration");
        m["file_path"] = query.value("file_path");
        list.append(m);
    }
    return list;
}

// --- Recent Plays ---
bool Database::addRecentPlay(int songId)
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO recent_plays(song_id) VALUES(?)"));
    query.addBindValue(songId);
    return query.exec();
}

QVariantList Database::getRecentPlays(int limit) const
{
    QVariantList list;
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT s.*, rp.played_at FROM recent_plays rp "
        "JOIN songs s ON s.id = rp.song_id "
        "ORDER BY rp.played_at DESC LIMIT ?"));
    query.addBindValue(limit);
    query.exec();
    while (query.next()) {
        QVariantMap m;
        m["id"] = query.value("id");
        m["title"] = query.value("title");
        m["artist"] = query.value("artist");
        m["played_at"] = query.value("played_at");
        list.append(m);
    }
    return list;
}

// --- Favorite Places ---
bool Database::addFavoritePlace(const QVariantMap &place)
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO favorite_places(name, address, latitude, longitude) "
        "VALUES(:name, :address, :lat, :lon)"));
    query.bindValue(":name", place["name"].toString());
    query.bindValue(":address", place["address"].toString());
    query.bindValue(":lat", place["latitude"].toDouble());
    query.bindValue(":lon", place["longitude"].toDouble());
    return query.exec();
}

QVariantList Database::getFavoritePlaces() const
{
    QVariantList list;
    QSqlQuery query(m_db);
    query.exec(QStringLiteral("SELECT * FROM favorite_places ORDER BY name"));
    while (query.next()) {
        QVariantMap m;
        m["id"] = query.value("id");
        m["name"] = query.value("name");
        m["address"] = query.value("address");
        m["latitude"] = query.value("latitude");
        m["longitude"] = query.value("longitude");
        list.append(m);
    }
    return list;
}

// --- Call Logs ---
bool Database::addCallLog(const QVariantMap &call)
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO call_logs(contact, phone, direction, duration) "
        "VALUES(:contact, :phone, :direction, :duration)"));
    query.bindValue(":contact", call["contact"].toString());
    query.bindValue(":phone", call["phone"].toString());
    query.bindValue(":direction", call["direction"].toString());
    query.bindValue(":duration", call["duration"].toInt());
    return query.exec();
}

QVariantList Database::getCallLogs(int limit) const
{
    QVariantList list;
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT * FROM call_logs ORDER BY called_at DESC LIMIT ?"));
    query.addBindValue(limit);
    query.exec();
    while (query.next()) {
        QVariantMap m;
        m["id"] = query.value("id");
        m["contact"] = query.value("contact");
        m["phone"] = query.value("phone");
        m["direction"] = query.value("direction");
        m["duration"] = query.value("duration");
        m["called_at"] = query.value("called_at");
        list.append(m);
    }
    return list;
}
