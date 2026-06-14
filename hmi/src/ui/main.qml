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
    // 渐变科技风颜色方案
    // ============================================================
    readonly property color colorBg:        "#080c17"
    readonly property color colorSurface:   "#111a2e"
    readonly property color colorPrimary:   "#00d4ff"
    readonly property color colorAccent:    "#a855f7"
    readonly property color colorText:      "#e0e8f0"
    readonly property color colorTextSec:   "#7b89a0"
    readonly property color colorDanger:    "#ff4466"
    readonly property color colorSuccess:   "#00e676"
    readonly property color colorWarning:   "#ffb300"
    readonly property color colorNavActive:   "#00d4ff"
    readonly property color colorNavInactive: "#4a5568"
    readonly property color colorSeparator: "#1e2a45"

    // 发光色（用于阴影/光晕模拟）
    readonly property color glowPrimary:    "#40" + "00d4ff"
    readonly property color glowAccent:     "#40" + "a855f7"
    readonly property color glowDanger:     "#40" + "ff4466"
    readonly property color glowSuccess:    "#40" + "00e676"

    // 渐变（用于多层叠加模拟渐变）
    readonly property color gradCyan:  "#00d4ff"
    readonly property color gradBlue:  "#3b82f6"
    readonly property color gradPurple: "#a855f7"
    readonly property color gradPink:  "#ec4899"

    background: Rectangle {
        color: root.colorBg
    }

    // ============================================================
    // 页面路由常量
    // ============================================================
    readonly property int pagePlayer:     0
    readonly property int pageNavigation: 1
    readonly property int pageBluetooth:  2
    readonly property int pageVehicle:    3
    readonly property int pageSettings:   4
    readonly property int pageAgentChat:  5

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
            Layout.preferredHeight: 50
            color: root.colorSurface

            // 底部发光分割线
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "transparent"

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 1
                    color: root.colorPrimary
                    opacity: 0.3
                }
            }

            RowLayout {
                anchors {
                    left: parent.left; leftMargin: 22
                    right: parent.right; rightMargin: 22
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
                    color: root.colorPrimary
                    font.pixelSize: 15
                    font.bold: true
                    opacity: 0.8
                    Timer {
                        interval: 1000; repeat: true; running: true
                        onTriggered: {
                            var d = new Date()
                            clockLabel.text = d.toLocaleTimeString(Qt.locale(), "HH:mm")
                        }
                    }
                }
            }
        }

        // ---------- 页面内容 ----------
        StackView {
            id: contentStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            replaceEnter: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
            }
            replaceExit: Transition {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 }
            }

            initialItem: PlayerPage {}
        }

        // ---------- 底栏导航 ----------
        NavBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
        }
    }

    // ============================================================
    // 页面切换
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
        if (page) { contentStack.replace(page) }
    }
}
