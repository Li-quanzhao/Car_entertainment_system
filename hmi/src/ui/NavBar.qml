import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 底部导航栏 — 渐变科技风
Rectangle {
    id: navBar
    color: root.colorSurface

    readonly property var navItems: [
        { icon: "\u266B",  label: qsTr("音乐"),    page: 0 },
        { icon: "\u2302",  label: qsTr("导航"),    page: 1 },
        { icon: "\u260E",  label: qsTr("蓝牙"),    page: 2 },
        { icon: "\u26FD",  label: qsTr("车辆"),    page: 3 },
        { icon: "\u2699",  label: qsTr("设置"),    page: 4 },
        { icon: "\u2728",  label: qsTr("AI助手"),  page: 5 }
    ]

    // 顶部发光分割线
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: root.colorPrimary
        opacity: 0.2
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: navItems
            delegate: navButton
        }
    }

    Component {
        id: navButton
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            property bool isActive: contentStack.currentIndex === modelData.page
            property color accentColor: isActive ? root.colorPrimary : root.colorNavInactive

            // 选中渐变指示器
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 2
                width: 36
                height: 3
                radius: 2
                visible: isActive

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.gradCyan }
                    GradientStop { position: 0.5; color: root.gradBlue }
                    GradientStop { position: 1.0; color: root.gradPurple }
                }
            }

            // 发光光晕（激活时）
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: -6
                width: 36
                height: 8
                radius: 4
                color: root.colorPrimary
                opacity: isActive ? 0.12 : 0
            }

            ColumnLayout {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 2
                spacing: 3

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.icon
                    color: accentColor
                    font.pixelSize: 21
                    opacity: isActive ? 1 : 0.6
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.label
                    color: accentColor
                    font.pixelSize: 10
                    font.weight: isActive ? Font.Bold : Font.Normal
                    opacity: isActive ? 0.9 : 0.5
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.switchPage(modelData.page)
            }
        }
    }
}
