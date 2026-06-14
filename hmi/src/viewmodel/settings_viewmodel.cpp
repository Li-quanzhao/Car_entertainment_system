#include "settings_viewmodel.h"
#include "../infrastructure/config_manager.h"

SettingsViewModel::SettingsViewModel(ConfigManager *config, QObject *parent)
    : QObject(parent)
    , m_config(config)
{
    // 从持久化配置加载初始值
    m_theme = m_config->theme();
    m_language = m_config->language();
    m_volume = m_config->get("volume", 0.5).toReal();
}

void SettingsViewModel::setTheme(const QString &theme)
{
    if (m_theme != theme && (theme == "dark" || theme == "light")) {
        m_theme = theme;
        m_config->setTheme(theme);
        emit themeChanged(theme);
        emit infoMessage(QStringLiteral("主题已切换: %1").arg(theme));
    }
}

void SettingsViewModel::setLanguage(const QString &language)
{
    QString langCode = (language == "English") ? "en" : "zh";
    if (m_language != langCode) {
        m_language = langCode;
        m_config->setLanguage(langCode);
        emit languageChanged(langCode);
        emit infoMessage(m_language == "en"
            ? QStringLiteral("Language switched to English")
            : QStringLiteral("语言已切换为中文"));
    }
}

void SettingsViewModel::setVolume(qreal vol)
{
    m_volume = qBound(0.0, vol, 1.0);
    m_config->set("volume", m_volume);
    emit volumeChanged(m_volume);
}
