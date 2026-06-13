#ifndef CONFIG_SERVICE_H
#define CONFIG_SERVICE_H

#include <QObject>
#include "../infrastructure/config_manager.h"

class ConfigService : public QObject
{
    Q_OBJECT

public:
    explicit ConfigService(ConfigManager *config, QObject *parent = nullptr);

    QString theme() const;
    void setTheme(const QString &theme);
    QString language() const;
    void setLanguage(const QString &language);

signals:
    void themeChanged(const QString &theme);
    void languageChanged(const QString &language);

private:
    ConfigManager *m_config;
};

#endif // CONFIG_SERVICE_H
