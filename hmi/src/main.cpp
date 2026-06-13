#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSurfaceFormat>

#include "service/agent_http_client.h"
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

    // Qt Quick 启用抗锯齿
    QSurfaceFormat format;
    format.setSamples(4);
    QSurfaceFormat::setDefaultFormat(format);

    QQmlApplicationEngine engine;

    // ============================================================
    // 创建并注册 ViewModel & Service（通过 context property 暴露给 QML）
    // ============================================================
    AgentHttpClient agentClient;
    PlayerViewModel playerVM;
    NavViewModel navVM;
    BluetoothViewModel bluetoothVM;
    VehicleViewModel vehicleVM;
    SettingsViewModel settingsVM;

    // 启动车辆数据模拟
    vehicleVM.startSimulation();

    // 加载演示歌曲
    playerVM.loadDemoSongs();

    // Agent 聊天
    AgentViewModel agentVM(&agentClient);

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
