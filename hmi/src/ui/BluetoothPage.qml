import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 蓝牙电话页面
Item {
    id: page
    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 24

        // ============================================================
        // 左侧：设备列表
        // ============================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.4
            color: root.colorSurface
            radius: 12

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // 标题栏
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.bottomMargin: 8

                    Label {
                        text: qsTr("蓝牙设备")
                        color: root.colorText
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Button {
                        text: bluetoothVM.discovering ? qsTr("扫描中...") : qsTr("扫描")
                        font.pixelSize: 11
                        enabled: !bluetoothVM.discovering
                        onClicked: bluetoothVM.startDiscovery()
                        Layout.preferredHeight: 30

                        background: Rectangle {
                            radius: 6
                            color: parent.hovered ? root.colorPrimary : "transparent"
                            border.color: root.colorPrimary
                            border.width: 1
                        }
                        contentItem: Label {
                            text: parent.text
                            color: bluetoothVM.discovering ? root.colorTextSec : root.colorPrimary
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.colorSeparator
                }

                // 设备列表
                ListView {
                    id: deviceList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: bluetoothVM.devices
                    clip: true

                    delegate: Item {
                        width: ListView.view.width
                        height: 48

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 8
                            color: mouseArea.containsMouse ? root.colorSeparator : "transparent"
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 16
                                rightMargin: 16
                            }
                            spacing: 12

                            Label {
                                text: "\uD83D\uDCF1"
                                font.pixelSize: 20
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: modelData.name || ""
                                    color: root.colorText
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: modelData.address || ""
                                    color: root.colorTextSec
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                }
                            }

                            Button {
                                text: (bluetoothVM.connected && bluetoothVM.deviceName === (modelData.name || ""))
                                      ? qsTr("断开") : qsTr("连接")
                                font.pixelSize: 11
                                Layout.preferredWidth: 52
                                Layout.preferredHeight: 28
                                visible: modelData.address !== ""

                                onClicked: {
                                    if (bluetoothVM.connected && bluetoothVM.deviceName === (modelData.name || "")) {
                                        bluetoothVM.disconnectDevice()
                                    } else {
                                        bluetoothVM.connectToDevice(modelData.address, modelData.name)
                                    }
                                }

                                background: Rectangle {
                                    radius: 4
                                    color: bluetoothVM.connected && bluetoothVM.deviceName === (modelData.name || "")
                                           ? root.colorDanger : root.colorPrimary
                                }
                                contentItem: Label {
                                    text: parent.text
                                    color: "white"
                                    font: parent.font
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }

                    // 空状态
                    Label {
                        anchors.centerIn: parent
                        text: bluetoothVM.discovering ? qsTr("正在扫描...") : qsTr("点击扫描查找设备")
                        color: root.colorTextSec
                        font.pixelSize: 13
                        visible: deviceList.count === 0
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }
                }
            }
        }

        // ============================================================
        // 右侧：连接状态 + 拨号盘
        // ============================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: root.colorSurface
            radius: 12

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 24
                }
                spacing: 16

                Item { Layout.fillHeight: true }

                // 连接状态
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 80
                        height: 80
                        radius: 40
                        color: bluetoothVM.connected ? root.colorSuccess : root.colorSeparator

                        Label {
                            anchors.centerIn: parent
                            text: "\u260E"
                            color: "white"
                            font.pixelSize: 36
                        }
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: bluetoothVM.connected ? bluetoothVM.deviceName : qsTr("未连接")
                        color: root.colorText
                        font.pixelSize: 16
                        font.bold: true
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: bluetoothVM.connected ? qsTr("已连接") : qsTr("请选择设备连接")
                        color: bluetoothVM.connected ? root.colorSuccess : root.colorTextSec
                        font.pixelSize: 12
                    }
                }

                Item { Layout.preferredHeight: 16 }

                // 拨号盘
                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 3
                    rowSpacing: 8
                    columnSpacing: 8

                    Repeater {
                        model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"]

                        Button {
                            text: modelData
                            font.pixelSize: 18
                            implicitWidth: 56
                            implicitHeight: 48
                            enabled: bluetoothVM.connected

                            onClicked: phoneInput.text += modelData

                            background: Rectangle {
                                radius: 8
                                color: parent.hovered ? root.colorPrimary : root.colorSeparator
                                opacity: parent.hovered ? 0.15 : 0.5
                            }
                            contentItem: Label {
                                text: parent.text
                                color: root.colorText
                                font: parent.font
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                // 号码显示
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: 250
                    spacing: 8

                    TextField {
                        id: phoneInput
                        Layout.fillWidth: true
                        placeholderText: qsTr("输入号码")
                        color: root.colorText
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        readOnly: true

                        background: Rectangle {
                            radius: 6
                            color: root.colorBg
                            border.color: root.colorSeparator
                        }

                        // 退格
                        Keys.onPressed: {
                            if (event.key === Qt.Key_Backspace) {
                                phoneInput.text = phoneInput.text.slice(0, -1)
                            }
                        }
                    }

                    Button {
                        text: "\u232B"
                        font.pixelSize: 14
                        implicitWidth: 36
                        implicitHeight: 36

                        onClicked: phoneInput.text = phoneInput.text.slice(0, -1)

                        background: Rectangle {
                            radius: 4
                            color: parent.hovered ? root.colorSeparator : "transparent"
                        }
                        contentItem: Label {
                            text: parent.text
                            color: root.colorText
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                // 拨号按钮
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    Button {
                        text: "\uD83D\uDCDE"
                        font.pixelSize: 22
                        implicitWidth: 64
                        implicitHeight: 48
                        enabled: bluetoothVM.connected && phoneInput.text.length > 0

                        onClicked: bluetoothVM.dial(phoneInput.text)

                        background: Rectangle {
                            radius: 8
                            color: root.colorSuccess
                            opacity: parent.enabled ? 1 : 0.3
                        }
                        contentItem: Label {
                            text: parent.text
                            color: "white"
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: "\uD83D\uDCD5"
                        font.pixelSize: 22
                        implicitWidth: 64
                        implicitHeight: 48
                        enabled: bluetoothVM.connected

                        onClicked: bluetoothVM.endCall()

                        background: Rectangle {
                            radius: 8
                            color: root.colorDanger
                            opacity: parent.enabled ? 1 : 0.3
                        }
                        contentItem: Label {
                            text: parent.text
                            color: "white"
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
