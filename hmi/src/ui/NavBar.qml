import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 底部导航栏
Rectangle {
    id: navBar
    color: root.colorSurface

    // 导航项定义
    readonly property var navItems: [
        { icon: "\u266B",  label: qsTr("音乐"),    page: 0 },
        { icon: "\u2302",  label: qsTr("导航"),    page: 1 },
        { icon: "\u260E",  label: qsTr("蓝牙"),    page: 2 },
        { icon: "\u26FD",  label: qsTr("车辆"),    page: 3 },
        { icon: "\u2699",  label: qsTr("设置"),    page: 4 },
        { icon: "\u2728",  label: qsTr("AI助手"),  page: 5 }
    ]

    // 顶部分隔线
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: root.colorSeparator
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

            // 选中指示器
            Rectangle {
                anchors.top: parent.top
                width: 40
                height: 3
                radius: 2
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.colorNavActive
                visible: contentStack.currentIndex === modelData.page
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.icon
                    color: contentStack.currentIndex === modelData.page
                           ? root.colorNavActive : root.colorNavInactive
                    font.pixelSize: 20
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.label
                    color: contentStack.currentIndex === modelData.page
                           ? root.colorNavActive : root.colorNavInactive
                    font.pixelSize: 10
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.switchPage(modelData.page)
            }
        }
    }
}
