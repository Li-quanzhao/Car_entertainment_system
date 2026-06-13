#include "config_manager.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QFile>
#include <QDir>
#include <QStandardPaths>

ConfigManager::ConfigManager(QObject *parent)
    : QObject(parent)
{
    QString appDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir().mkpath(appDir);
    m_configPath = appDir + QStringLiteral("/car_hmi_config.json");
    load();
}

ConfigManager::~ConfigManager() = default;

void ConfigManager::setTheme(const QString &theme)
{
    if (m_theme != theme) {
        m_theme = theme;
        m_data["theme"] = theme;
        emit themeChanged(theme);
        save();
    }
}

void ConfigManager::setLanguage(const QString &language)
{
    if (m_language != language) {
        m_language = language;
        m_data["language"] = language;
        emit languageChanged(language);
        save();
    }
}

QVariant ConfigManager::get(const QString &key, const QVariant &defaultValue) const
{
    QJsonValue val = m_data.value(key);
    if (val.isUndefined() || val.isNull())
        return defaultValue;
    return val.toVariant();
}

void ConfigManager::set(const QString &key, const QVariant &value)
{
    m_data[key] = QJsonValue::fromVariant(value);
    save();
}

void ConfigManager::load()
{
    QFile file(m_configPath);
    if (!file.exists()) {
        m_data["theme"]    = m_theme;
        m_data["language"] = m_language;
        save();
        emit configLoaded();
        return;
    }
    if (!file.open(QIODevice::ReadOnly)) return;

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();

    if (doc.isObject()) {
        m_data = doc.object();
        m_theme    = m_data["theme"].toString(QStringLiteral("dark"));
        m_language = m_data["language"].toString(QStringLiteral("zh"));
    }
    emit configLoaded();
}

void ConfigManager::save()
{
    QFile file(m_configPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) return;
    file.write(QJsonDocument(m_data).toJson(QJsonDocument::Indented));
    file.close();
}
