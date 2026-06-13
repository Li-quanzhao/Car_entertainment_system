#ifndef SETTINGS_VIEWMODEL_H
#define SETTINGS_VIEWMODEL_H

#include <QObject>
#include <QStringList>

class SettingsViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(QStringList languages READ languages CONSTANT)
    Q_PROPERTY(QStringList themes READ themes CONSTANT)

public:
    explicit SettingsViewModel(QObject *parent = nullptr);

    QString theme() const { return m_theme; }
    void setTheme(const QString &theme);
    QString language() const { return m_language; }
    void setLanguage(const QString &language);
    qreal volume() const { return m_volume; }
    void setVolume(qreal vol);
    QStringList languages() const { return {QStringLiteral("中文"), QStringLiteral("English")}; }
    QStringList themes() const { return {QStringLiteral("dark"), QStringLiteral("light")}; }

signals:
    void themeChanged(const QString &theme);
    void languageChanged(const QString &language);
    void volumeChanged(qreal volume);
    void infoMessage(const QString &msg);

private:
    QString m_theme = QStringLiteral("dark");
    QString m_language = QStringLiteral("zh");
    qreal m_volume = 0.5;
};

#endif // SETTINGS_VIEWMODEL_H
