#include "settings_viewmodel.h"

SettingsViewModel::SettingsViewModel(QObject *parent)
    : QObject(parent)
{
}

void SettingsViewModel::setTheme(const QString &theme)
{
    if (m_theme != theme && (theme == "dark" || theme == "light")) {
        m_theme = theme;
        emit themeChanged(theme);
        emit infoMessage(QStringLiteral("主题已切换: %1").arg(theme));
    }
}

void SettingsViewModel::setLanguage(const QString &language)
{
    QString langCode = (language == "English") ? "en" : "zh";
    if (m_language != langCode) {
        m_language = langCode;
        emit languageChanged(langCode);
        emit infoMessage(m_language == "en"
            ? QStringLiteral("Language switched to English")
            : QStringLiteral("语言已切换为中文"));
    }
}

void SettingsViewModel::setVolume(qreal vol)
{
    m_volume = qBound(0.0, vol, 1.0);
    emit volumeChanged(m_volume);
}
