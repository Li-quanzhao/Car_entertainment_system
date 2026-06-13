import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    title: "Car Entertainment System"
    width: 1024
    height: 600
    minimumWidth: 800
    minimumHeight: 480

    // ============================================================
    // 全局颜色方案（由 settingsVM.theme 驱动）
    // ============================================================
    readonly property color colorBg:        settingsVM.theme === "light" ? "#f5f5f5" : "#0d1117"
    readonly property color colorSurface:   settingsVM.theme === "light" ? "#ffffff" : "#161b22"
    readonly property color colorPrimary:   settingsVM.theme === "light" ? "#1a73e8" : "#58a6ff"
    readonly property color colorText:      settingsVM.theme === "light" ? "#1f2328" : "#e6edf3"
    readonly property color colorTextSec:   settingsVM.theme === "light" ? "#656d76" : "#8b949e"
    readonly property color colorAccent:    settingsVM.theme === "light" ? "#34a853" : "#3fb950"
    readonly property color colorNavActive: settingsVM.theme === "light" ? "#1a73e8" : "#58a6ff"
    readonly property color colorNavInactive: settingsVM.theme === "light" ? "#656d76" : "#484f58"
    readonly property color colorSeparator: settingsVM.theme === "light" ? "#d0d7de" : "#30363d"

    background: Rectangle { color: root.colorBg }

    // ============================================================
    // 页面路由常量
    // ============================================================
    readonly property int pagePlayer:     0
    readonly property int pageNavigation: 1
    readonly property int pageBluetooth:  2
    readonly property int pageVehicle:    3
    readonly property int pageSettings:   4
    readonly property int pageAgentChat:  5

    // 页面标题映射
    function pageTitle(page) {
        const titles = [qsTr("音乐"), qsTr("导航"), qsTr("蓝牙"),
                        qsTr("车辆"), qsTr("设置"), qsTr("AI助手")]
        return titles[page] || ""
    }

    // ============================================================
    // 布局
    // ============================================================
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- 顶栏 ----------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: root.colorSurface

            RowLayout {
                anchors {
                    left: parent.left; leftMargin: 20
                    right: parent.right; rightMargin: 20
                    verticalCenter: parent.verticalCenter
                }

                Label {
                    text: pageTitle(contentStack.currentIndex)
                    color: root.colorText
                    font.pixelSize: 18
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Label {
                    id: clockLabel
                    color: root.colorTextSec
                    font.pixelSize: 14
                    Timer {
                        interval: 1000
                        repeat: true
                        running: true
                        onTriggered: {
                            var d = new Date()
                            clockLabel.text = d.toLocaleTimeString(Qt.locale(), "HH:mm")
                        }
                    }
                }
            }

            // 底部分隔线
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: root.colorSeparator
            }
        }

        // ---------- 页面内容 ----------
        StackView {
            id: contentStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // 替换动画
            replaceEnter: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
            }
            replaceExit: Transition {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
            }

            initialItem: PlayerPage {}
        }

        // ---------- 底栏导航 ----------
        NavBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
        }
    }

    // ============================================================
    // 页面切换（被 NavBar 调用）
    // ============================================================
    function switchPage(pageIndex) {
        if (contentStack.currentIndex === pageIndex)
            return

        var page
        switch (pageIndex) {
        case 0: page = Qt.createComponent("PlayerPage.qml");       break
        case 1: page = Qt.createComponent("NavigationPage.qml");   break
        case 2: page = Qt.createComponent("BluetoothPage.qml");    break
        case 3: page = Qt.createComponent("VehiclePage.qml");      break
        case 4: page = Qt.createComponent("SettingsPage.qml");     break
        case 5: page = Qt.createComponent("AgentChatPage.qml");    break
        }
        if (page) {
            contentStack.replace(page)
        }
    }
}
