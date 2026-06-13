#include "config_service.h"

ConfigService::ConfigService(ConfigManager *config, QObject *parent)
    : QObject(parent)
    , m_config(config)
{
    connect(m_config, &ConfigManager::themeChanged, this, &ConfigService::themeChanged);
    connect(m_config, &ConfigManager::languageChanged, this, &ConfigService::languageChanged);
}

QString ConfigService::theme() const { return m_config->theme(); }
void ConfigService::setTheme(const QString &theme) { m_config->setTheme(theme); }
QString ConfigService::language() const { return m_config->language(); }
void ConfigService::setLanguage(const QString &language) { m_config->setLanguage(language); }
