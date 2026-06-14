#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSurfaceFormat>
#include <QTranslator>
#include <QLocale>

#include "infrastructure/audio_engine.h"
#include "infrastructure/database.h"
#include "infrastructure/bluetooth_adapter.h"
#include "infrastructure/config_manager.h"
#include "service/agent_http_client.h"
#include "service/media_service.h"
#include "service/bluetooth_service.h"
#include "service/map_service.h"
#include "service/vehicle_service.h"
#include "viewmodel/player_viewmodel.h"
#include "viewmodel/nav_viewmodel.h"
#include "viewmodel/bluetooth_viewmodel.h"
#include "viewmodel/vehicle_viewmodel.h"
#include "viewmodel/settings_viewmodel.h"
#include "viewmodel/agent_viewmodel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("CarHMI");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("CarEntertainment");

    // ============================================================
    // 加载翻译（逐步降级：完整 locale → 语言代码 → zh_CN 兜底）
    // ============================================================
    QTranslator translator;
    const QStringList uiLanguages = QLocale::system().uiLanguages();
    bool loaded = false;
    for (const QString &locale : uiLanguages) {
        const QLocale ql(locale);
        if (translator.load(":/i18n/" + ql.name())) {
            loaded = true;
            break;
        }
        const QString lang = ql.name().left(2);
        if (lang.size() == 2 && translator.load(":/i18n/" + lang)) {
            loaded = true;
            break;
        }
    }
    if (!loaded) {
        loaded = translator.load(":/i18n/zh_CN");
    }
    if (loaded) {
        app.installTranslator(&translator);
    }

    QSurfaceFormat format;
    format.setSamples(4);
    QSurfaceFormat::setDefaultFormat(format);

    // ============================================================
    // Infrastructure 层
    // ============================================================
    AudioEngine audio;
    Database db;
    db.initialize();  // SQLite 数据库初始化
    BluetoothAdapter btAdapter;
    ConfigManager configManager;

    // ============================================================
    // Service 层
    // ============================================================
    MediaService mediaService(&audio, &db);
    BluetoothService btService(&btAdapter, &db);
    MapService mapService(&db);
    VehicleService vehicleService;
    AgentHttpClient agentClient;

    // ============================================================
    // ViewModel 层（注入 Service 依赖）
    // ============================================================
    PlayerViewModel playerVM(&mediaService);
    NavViewModel navVM(&mapService);
    BluetoothViewModel bluetoothVM(&btService);
    VehicleViewModel vehicleVM(&vehicleService);
    SettingsViewModel settingsVM(&configManager);
    AgentViewModel agentVM(&agentClient);

    // 加载播放列表（从 Database 或演示歌曲）
    playerVM.loadPlaylist();
    vehicleVM.startSimulation();

    // ============================================================
    // QML 上下文注册
    // ============================================================
    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("audio", &audio);
    engine.rootContext()->setContextProperty("db", &db);
    engine.rootContext()->setContextProperty("btAdapter", &btAdapter);
    engine.rootContext()->setContextProperty("configManager", &configManager);
    engine.rootContext()->setContextProperty("mediaService", &mediaService);
    engine.rootContext()->setContextProperty("btService", &btService);
    engine.rootContext()->setContextProperty("mapService", &mapService);
    engine.rootContext()->setContextProperty("agentClient", &agentClient);
    engine.rootContext()->setContextProperty("agentVM", &agentVM);
    engine.rootContext()->setContextProperty("playerVM", &playerVM);
    engine.rootContext()->setContextProperty("navVM", &navVM);
    engine.rootContext()->setContextProperty("bluetoothVM", &bluetoothVM);
    engine.rootContext()->setContextProperty("vehicleVM", &vehicleVM);
    engine.rootContext()->setContextProperty("settingsVM", &settingsVM);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
