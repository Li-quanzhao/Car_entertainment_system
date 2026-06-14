import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 导航页面
Item {
    id: page
    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 24

        // ============================================================
        // 左侧：POI 搜索 + 结果列表
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

                // 搜索栏
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.bottomMargin: 8
                    spacing: 8

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        placeholderText: qsTr("搜索地点...")
                        color: root.colorText
                        font.pixelSize: 13

                        background: Rectangle {
                            radius: 8
                            color: root.colorBg
                            border.color: root.colorSeparator
                        }

                        onAccepted: navVM.searchPoi(text)
                    }

                    Button {
                        text: qsTr("搜索")
                        font.pixelSize: 12
                        Layout.preferredHeight: 32

                        onClicked: navVM.searchPoi(searchInput.text)

                        background: Rectangle {
                            radius: 6
                            color: root.colorPrimary
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

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.colorSeparator
                }

                // 结果列表
                ListView {
                    id: resultList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: navVM.poiResults
                    clip: true

                    delegate: Item {
                        width: ListView.view.width
                        height: 64

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

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: root.colorPrimary
                                opacity: 0.15

                                Label {
                                    anchors.centerIn: parent
                                    text: "\uD83D\uDCCD"
                                    font.pixelSize: 18
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: modelData.name || ""
                                    color: root.colorText
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: modelData.address || qsTr("%1, %2")
                                        .arg((modelData.latitude || 0).toFixed(4))
                                        .arg((modelData.longitude || 0).toFixed(4))
                                    color: root.colorTextSec
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Button {
                                text: qsTr("导航")
                                font.pixelSize: 11
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 28

                                onClicked: navVM.navigateTo(
                                    modelData.name || "",
                                    modelData.latitude || 0,
                                    modelData.longitude || 0)

                                background: Rectangle {
                                    radius: 4
                                    color: root.colorPrimary
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

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("输入关键词搜索地点")
                        color: root.colorTextSec
                        font.pixelSize: 13
                        visible: resultList.count === 0
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }
                }
            }
        }

        // ============================================================
        // 右侧：地图占位 + 导航信息
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

                // 地图占位区域
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 160
                    radius: 12
                    color: root.colorBg
                    border.color: root.colorSeparator

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uD83D\uDDFA\uFE0F"
                            font.pixelSize: 48
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: qsTr("地图区域")
                            color: root.colorTextSec
                            font.pixelSize: 14
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: qsTr("接入地图SDK后可显示实时地图")
                            color: root.colorTextSec
                            font.pixelSize: 11
                        }
                    }
                }

                // 导航信息卡片
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    radius: 12
                    color: navVM.navigating ? root.colorPrimary : root.colorSeparator
                    opacity: 0.15

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: navVM.navigating ? navVM.destination : qsTr("未开始导航")
                            color: root.colorText
                            font.pixelSize: 16
                            font.bold: true
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 24
                            visible: navVM.navigating

                            ColumnLayout {
                                spacing: 2
                                Layout.alignment: Qt.AlignHCenter

                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: navVM.distanceKm.toFixed(1) + " km"
                                    color: root.colorPrimary
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: qsTr("距离")
                                    color: root.colorTextSec
                                    font.pixelSize: 11
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.alignment: Qt.AlignHCenter

                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: navVM.etaMinutes + qsTr(" 分钟")
                                    color: root.colorAccent
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: qsTr("预计时间")
                                    color: root.colorTextSec
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }

                // 取消导航
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("取消导航")
                    font.pixelSize: 12
                    visible: navVM.navigating
                    implicitWidth: 100
                    implicitHeight: 32

                    onClicked: navVM.cancelNavigation()

                    background: Rectangle {
                        radius: 6
                        color: root.colorDanger
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
        }
    }
}
