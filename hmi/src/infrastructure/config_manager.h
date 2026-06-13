#ifndef CONFIG_MANAGER_H
#define CONFIG_MANAGER_H

#include <QObject>
#include <QString>
#include <QJsonObject>
#include <QSettings>

class ConfigManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)

public:
    explicit ConfigManager(QObject *parent = nullptr);
    ~ConfigManager() override;

    QString theme() const { return m_theme; }
    void setTheme(const QString &theme);

    QString language() const { return m_language; }
    void setLanguage(const QString &language);

    // 通用配置读写
    QVariant get(const QString &key, const QVariant &defaultValue = QVariant()) const;
    void set(const QString &key, const QVariant &value);

    // 加载/保存
    void load();
    void save();

signals:
    void themeChanged(const QString &theme);
    void languageChanged(const QString &language);
    void configLoaded();

private:
    QString m_configPath;
    QString m_theme  = QStringLiteral("dark");
    QString m_language = QStringLiteral("zh");
    QJsonObject m_data;
};

#endif // CONFIG_MANAGER_H
