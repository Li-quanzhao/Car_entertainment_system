import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 蓝牙电话页面 — 渐变科技风
Item {
    id: page
    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 24

        // 左侧：设备列表
        SciFiCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.4
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.bottomMargin: 8

                    Label {
                        text: qsTr("蓝牙设备")
                        color: root.colorPrimary
                        font.pixelSize: 14
                        font.bold: true
                        opacity: 0.85
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: scanBtnText.implicitWidth + 24
                        radius: 6
                        color: "transparent"
                        border.color: root.colorPrimary
                        border.width: 1
                        opacity: bluetoothVM.discovering ? 0.3 : 0.8

                        Label {
                            id: scanBtnText
                            anchors.centerIn: parent
                            text: bluetoothVM.discovering ? qsTr("扫描中...") : qsTr("扫描")
                            color: root.colorPrimary
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !bluetoothVM.discovering
                            onClicked: bluetoothVM.startDiscovery()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.colorSeparator
                }

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
                                leftMargin: 16; rightMargin: 16
                            }
                            spacing: 12

                            Label { text: "\uD83D\uDCF1"; font.pixelSize: 20 }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label {
                                    text: modelData.name || ""; color: root.colorText
                                    font.pixelSize: 13; elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: modelData.address || ""; color: root.colorTextSec
                                    font.pixelSize: 10; font.family: "monospace"
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 52; Layout.preferredHeight: 28
                                radius: 4
                                visible: modelData.address !== ""
                                color: (bluetoothVM.connected && bluetoothVM.deviceName === (modelData.name || ""))
                                       ? root.colorDanger : root.colorPrimary

                                Label {
                                    anchors.centerIn: parent
                                    text: (bluetoothVM.connected && bluetoothVM.deviceName === (modelData.name || ""))
                                          ? qsTr("断开") : qsTr("连接")
                                    color: "white"; font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (bluetoothVM.connected && bluetoothVM.deviceName === (modelData.name || ""))
                                            bluetoothVM.disconnectDevice()
                                        else
                                            bluetoothVM.connectToDevice(modelData.address, modelData.name)
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea; anchors.fill: parent; hoverEnabled: true
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: bluetoothVM.discovering ? qsTr("正在扫描...") : qsTr("点击扫描查找设备")
                        color: root.colorTextSec; font.pixelSize: 13
                        visible: deviceList.count === 0
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: true; policy: ScrollBar.AsNeeded
                    }
                }
            }
        }

        // 右侧：连接状态 + 拨号盘
        SciFiCard {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors { fill: parent; margins: 24 }
                spacing: 16

                Item { Layout.fillHeight: true }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 80; height: 80; radius: 40
                        gradient: Gradient {
                            GradientStop { position: 0; color: root.gradCyan }
                            GradientStop { position: 1; color: root.gradPurple }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: "\u260E"; color: "white"; font.pixelSize: 36
                        }
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: bluetoothVM.connected ? bluetoothVM.deviceName : qsTr("未连接")
                        color: root.colorText; font.pixelSize: 16; font.bold: true
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: bluetoothVM.connected ? qsTr("已连接") : qsTr("请选择设备连接")
                        color: bluetoothVM.connected ? root.colorSuccess : root.colorTextSec
                        font.pixelSize: 12
                    }
                }

                Item { Layout.preferredHeight: 16 }

                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 3; rowSpacing: 8; columnSpacing: 8

                    Repeater {
                        model: ["1","2","3","4","5","6","7","8","9","*","0","#"]
                        delegate: Rectangle {
                            implicitWidth: 56; implicitHeight: 48; radius: 8
                            color: mouseDial.containsMouse ? root.colorPrimary : root.colorSeparator
                            opacity: mouseDial.containsMouse ? 0.15 : 0.4

                            Label {
                                anchors.centerIn: parent
                                text: modelData; color: root.colorText; font.pixelSize: 18
                            }
                            MouseArea {
                                id: mouseDial; anchors.fill: parent; hoverEnabled: true
                                enabled: bluetoothVM.connected
                                onClicked: phoneInput.text += modelData
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true; Layout.maximumWidth: 250
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 40
                        radius: 8; color: root.colorBg
                        border.color: root.colorSeparator; border.width: 1

                        TextInput {
                            id: phoneInput
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                            color: root.colorText; font.pixelSize: 16
                            verticalAlignment: TextInput.AlignVCenter
                            readOnly: true
                        }
                    }

                    Rectangle {
                        implicitWidth: 36; implicitHeight: 36; radius: 4
                        color: mouseDel.containsMouse ? root.colorSeparator : "transparent"

                        Label {
                            anchors.centerIn: parent
                            text: "\u232B"; color: root.colorText; font.pixelSize: 14
                        }
                        MouseArea {
                            id: mouseDel; anchors.fill: parent; hoverEnabled: true
                            onClicked: phoneInput.text = phoneInput.text.slice(0, -1)
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 16

                    Rectangle {
                        implicitWidth: 64; implicitHeight: 48; radius: 8
                        color: root.colorSuccess; opacity: phoneInput.text.length > 0 ? 1 : 0.3

                        Label {
                            anchors.centerIn: parent
                            text: "\uD83D\uDCDE"; color: "white"; font.pixelSize: 22
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: bluetoothVM.connected && phoneInput.text.length > 0
                            onClicked: bluetoothVM.dial(phoneInput.text)
                        }
                    }

                    Rectangle {
                        implicitWidth: 64; implicitHeight: 48; radius: 8
                        color: root.colorDanger; opacity: 0.8

                        Label {
                            anchors.centerIn: parent
                            text: "\uD83D\uDCD5"; color: "white"; font.pixelSize: 22
                        }
                        MouseArea {
                            anchors.fill: parent; enabled: bluetoothVM.connected
                            onClicked: bluetoothVM.endCall()
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
