#include <QtTest>
#include <QStandardPaths>
#include <QTemporaryDir>

#include "infrastructure/config_manager.h"

class TestConfigManager : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase()
    {
        // 重定向 QStandardPaths 到临时目录，避免污染真实配置
        QStandardPaths::setTestModeEnabled(true);
    }

    void testDefaultValues()
    {
        ConfigManager config;
        QCOMPARE(config.theme(), QString("dark"));
        QCOMPARE(config.language(), QString("zh"));
    }

    void testSetTheme()
    {
        ConfigManager config;
        config.setTheme("light");
        QCOMPARE(config.theme(), QString("light"));
    }

    void testSetLanguage()
    {
        ConfigManager config;
        config.setLanguage("en");
        QCOMPARE(config.language(), QString("en"));
    }

    void testCustomGetSet()
    {
        ConfigManager config;
        config.set("volume", 80);
        QCOMPARE(config.get("volume").toInt(), 80);
    }

    void testCustomGetDefault()
    {
        ConfigManager config;
        QVariant val = config.get("non_existent_key", 42);
        QCOMPARE(val.toInt(), 42);
    }

    void testPersistence()
    {
        // 创建并设置值
        ConfigManager config;
        config.setTheme("light");
        config.set("volume", 75);

        // 新建一个 ConfigManager 实例，检查值是否持久化
        ConfigManager reloaded;
        QCOMPARE(reloaded.theme(), QString("light"));
        QCOMPARE(reloaded.get("volume").toInt(), 75);
    }
};

QTEST_GUILESS_MAIN(TestConfigManager)
#include "test_config.moc"
