import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 导航页面 — 渐变科技风
Item {
    id: page
    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 24

        // 左侧：POI 搜索
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
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.bottomMargin: 8
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 36
                        radius: 8; color: root.colorBg
                        border.color: root.colorSeparator; border.width: 1

                        TextInput {
                            id: searchInput
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                            color: root.colorText; font.pixelSize: 13
                            verticalAlignment: TextInput.AlignVCenter
                            focus: true

                            Text {
                                anchors.fill: parent; anchors.leftMargin: 12
                                text: qsTr("搜索地点...")
                                color: root.colorTextSec; font.pixelSize: 13
                                visible: !searchInput.text
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 60; Layout.preferredHeight: 32
                        radius: 6
                        gradient: Gradient {
                            GradientStop { position: 0; color: root.gradCyan }
                            GradientStop { position: 1; color: root.gradBlue }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: qsTr("搜索"); color: "white"; font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: navVM.searchPoi(searchInput.text)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 1; color: root.colorSeparator
                }

                ListView {
                    id: resultList
                    Layout.fillWidth: true; Layout.fillHeight: true
                    model: navVM.poiResults; clip: true

                    delegate: Item {
                        width: ListView.view.width; height: 64

                        Rectangle {
                            anchors.fill: parent; anchors.margins: 2
                            radius: 8
                            color: mouseArea.containsMouse ? root.colorSeparator : "transparent"
                        }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                            spacing: 12

                            Rectangle {
                                width: 40; height: 40; radius: 20
                                gradient: Gradient {
                                    GradientStop { position: 0; color: root.gradCyan }
                                    GradientStop { position: 1; color: root.gradPurple }
                                }
                                opacity: 0.2

                                Label {
                                    anchors.centerIn: parent; text: "\uD83D\uDCCD"
                                    font.pixelSize: 18
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Label {
                                    text: modelData.name || ""; color: root.colorText
                                    font.pixelSize: 13; font.bold: true
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                                Label {
                                    text: modelData.address || qsTr("%1, %2")
                                        .arg((modelData.latitude || 0).toFixed(4))
                                        .arg((modelData.longitude || 0).toFixed(4))
                                    color: root.colorTextSec; font.pixelSize: 11
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 48; Layout.preferredHeight: 28
                                radius: 4; color: root.colorPrimary

                                Label {
                                    anchors.centerIn: parent
                                    text: qsTr("导航"); color: "white"; font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: navVM.navigateTo(
                                        modelData.name || "",
                                        modelData.latitude || 0,
                                        modelData.longitude || 0)
                                }
                            }
                        }

                        MouseArea { id: mouseArea; anchors.fill: parent; hoverEnabled: true }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("输入关键词搜索地点"); color: root.colorTextSec; font.pixelSize: 13
                        visible: resultList.count === 0
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: true; policy: ScrollBar.AsNeeded
                    }
                }
            }
        }

        // 右侧：地图 + 导航信息
        SciFiCard {
            Layout.fillWidth: true; Layout.fillHeight: true

            ColumnLayout {
                anchors { fill: parent; margins: 24 }
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Layout.minimumHeight: 160; radius: 12
                    color: root.colorBg; border.color: root.colorSeparator

                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 8
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uD83D\uDDFA\uFE0F"; font.pixelSize: 48
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: qsTr("地图区域"); color: root.colorPrimary; font.pixelSize: 14
                            opacity: 0.7
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: qsTr("接入地图SDK后可显示实时地图")
                            color: root.colorTextSec; font.pixelSize: 11
                        }
                    }
                }

                SciFiCard {
                    Layout.fillWidth: true; Layout.preferredHeight: 100

                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 6

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: navVM.navigating ? navVM.destination : qsTr("未开始导航")
                            color: navVM.navigating ? root.colorPrimary : root.colorTextSec
                            font.pixelSize: 16; font.bold: true
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter; spacing: 24
                            visible: navVM.navigating

                            ColumnLayout { spacing: 2; Layout.alignment: Qt.AlignHCenter
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: navVM.distanceKm.toFixed(1) + " km"
                                    color: root.colorPrimary; font.pixelSize: 20; font.bold: true
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: qsTr("距离"); color: root.colorTextSec; font.pixelSize: 11
                                }
                            }
                            ColumnLayout { spacing: 2; Layout.alignment: Qt.AlignHCenter
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: navVM.etaMinutes + qsTr(" 分钟")
                                    color: root.colorAccent; font.pixelSize: 20; font.bold: true
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: qsTr("预计时间"); color: root.colorTextSec; font.pixelSize: 11
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 100; implicitHeight: 32; radius: 6
                    color: root.colorDanger; opacity: 0.8
                    visible: navVM.navigating

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("取消导航"); color: "white"; font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: navVM.cancelNavigation()
                    }
                }
            }
        }
    }
}
