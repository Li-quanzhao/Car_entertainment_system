import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 车辆信息页面 — 渐变科技风
Item {
    id: page
    anchors.fill: parent

    GridLayout {
        anchors.fill: parent
        anchors.margins: 16
        columns: 2; rowSpacing: 12; columnSpacing: 12

        // 速度表盘
        SciFiCard {
            Layout.fillWidth: true; Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent; spacing: 8

                Canvas {
                    id: speedCanvas
                    Layout.alignment: Qt.AlignHCenter
                    width: 150; height: 150

                    property real angle: -90 + (vehicleVM.speed / 180) * 270

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var cx = width / 2, cy = height / 2, r = width / 2 - 8

                        ctx.beginPath(); ctx.arc(cx, cy, r, Math.PI * 0.75, Math.PI * 2.25)
                        ctx.lineWidth = 6; ctx.strokeStyle = Qt.rgba(1,1,1,0.05); ctx.stroke()

                        ctx.beginPath(); ctx.arc(cx, cy, r, Math.PI * 0.75, (angle + 90) * Math.PI / 180)
                        ctx.lineWidth = 6
                        // 渐变模拟
                        var colorStop = angle / 270
                        if (colorStop < 0.5)
                            ctx.strokeStyle = Qt.rgba(0, 0.83, 1, 0.5 + colorStop * 0.5)
                        else if (colorStop < 0.8)
                            ctx.strokeStyle = Qt.rgba(1, 0.7, 0, 0.6 + colorStop * 0.3)
                        else
                            ctx.strokeStyle = Qt.rgba(1, 0.27, 0.4, 0.8)
                        ctx.stroke()
                    }

                    Connections {
                        target: vehicleVM
                        function onDataUpdated() { speedCanvas.requestPaint() }
                    }
                }

                Label {
                    anchors.centerIn: speedCanvas
                    text: vehicleVM.speed
                    color: vehicleVM.speed > 120 ? root.colorDanger
                            : vehicleVM.speed > 80 ? root.colorWarning : root.colorPrimary
                    font.pixelSize: 42; font.bold: true
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "km/h"; color: root.colorTextSec; font.pixelSize: 14
                }
            }
        }

        // 转速表盘
        SciFiCard {
            Layout.fillWidth: true; Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent; spacing: 8

                Canvas {
                    id: rpmCanvas
                    Layout.alignment: Qt.AlignHCenter
                    width: 150; height: 150

                    property real angle: -90 + (vehicleVM.rpm / 7000) * 270

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var cx = width / 2, cy = height / 2, r = width / 2 - 8

                        ctx.beginPath(); ctx.arc(cx, cy, r, Math.PI * 0.75, Math.PI * 2.25)
                        ctx.lineWidth = 6; ctx.strokeStyle = Qt.rgba(1,1,1,0.05); ctx.stroke()

                        ctx.beginPath(); ctx.arc(cx, cy, r, Math.PI * 0.75, (angle + 90) * Math.PI / 180)
                        ctx.lineWidth = 6
                        var pct = angle / 270
                        if (pct < 0.4)
                            ctx.strokeStyle = Qt.rgba(0.51, 0.83, 0.47, 0.5 + pct * 0.5)
                        else if (pct < 0.7)
                            ctx.strokeStyle = Qt.rgba(1, 0.7, 0, 0.6 + pct * 0.3)
                        else
                            ctx.strokeStyle = Qt.rgba(1, 0.27, 0.4, 0.8)
                        ctx.stroke()
                    }

                    Connections {
                        target: vehicleVM
                        function onDataUpdated() { rpmCanvas.requestPaint() }
                    }
                }

                Label {
                    anchors.centerIn: rpmCanvas
                    text: Math.round(vehicleVM.rpm / 100) * 100
                    color: vehicleVM.rpm > 5000 ? root.colorDanger
                            : vehicleVM.rpm > 3500 ? root.colorWarning : root.colorSuccess
                    font.pixelSize: 36; font.bold: true
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "RPM"; color: root.colorTextSec; font.pixelSize: 14
                }
            }
        }

        // 档位 + 油量 + 里程
        SciFiCard {
            Layout.fillWidth: true; Layout.fillHeight: true

            RowLayout {
                anchors.centerIn: parent; spacing: 24

                // 档位
                ColumnLayout { Layout.alignment: Qt.AlignHCenter; spacing: 4
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 56; height: 56; radius: 12
                        gradient: Gradient {
                            GradientStop { position: 0; color: root.gradCyan }
                            GradientStop { position: 1; color: root.gradBlue }
                        }
                        opacity: 0.2

                        Label {
                            anchors.centerIn: parent
                            text: vehicleVM.gear; color: root.colorPrimary
                            font.pixelSize: 24; font.bold: true
                        }
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("档位"); color: root.colorTextSec; font.pixelSize: 11
                    }
                }

                // 油量
                ColumnLayout { Layout.alignment: Qt.AlignHCenter; spacing: 4
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 56; height: 56; radius: 12
                        color: vehicleVM.fuelLevel < 0.15 ? root.colorDanger
                                : vehicleVM.fuelLevel < 0.3 ? root.colorWarning : root.colorSuccess
                        opacity: 0.2

                        Label {
                            anchors.centerIn: parent
                            text: Math.round(vehicleVM.fuelLevel * 100) + "%"
                            color: vehicleVM.fuelLevel < 0.15 ? root.colorDanger
                                    : vehicleVM.fuelLevel < 0.3 ? root.colorWarning : root.colorSuccess
                            font.pixelSize: 18; font.bold: true
                        }
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("油量"); color: root.colorTextSec; font.pixelSize: 11
                    }
                }

                // 里程
                ColumnLayout { Layout.alignment: Qt.AlignHCenter; spacing: 4
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 56; height: 56; radius: 12
                        color: root.colorAccent; opacity: 0.2

                        Label {
                            anchors.centerIn: parent
                            text: (vehicleVM.mileage / 1000).toFixed(0)
                            color: root.colorAccent
                            font.pixelSize: 18; font.bold: true
                        }
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("千km"); color: root.colorTextSec; font.pixelSize: 11
                    }
                }
            }
        }

        // 车门 + 水温
        SciFiCard {
            Layout.fillWidth: true; Layout.fillHeight: true

            RowLayout {
                anchors.centerIn: parent; spacing: 24

                ColumnLayout { Layout.alignment: Qt.AlignHCenter; spacing: 4
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 56; height: 56; radius: 12
                        color: vehicleVM.doorOpen ? root.colorWarning : root.colorSuccess
                        opacity: 0.15

                        Label {
                            anchors.centerIn: parent
                            text: vehicleVM.doorOpen ? "\uD83D\uDEAA" : "\uD83D\uDD12"
                            font.pixelSize: 24
                        }
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: vehicleVM.doorOpen ? qsTr("车门开") : qsTr("已锁")
                        color: vehicleVM.doorOpen ? root.colorWarning : root.colorSuccess
                        font.pixelSize: 12; font.bold: true
                    }
                }

                ColumnLayout { Layout.alignment: Qt.AlignHCenter; spacing: 4
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 56; height: 56; radius: 12
                        color: vehicleVM.engineTemp > 105 ? root.colorDanger
                                : vehicleVM.engineTemp > 95 ? root.colorWarning : root.colorSuccess
                        opacity: 0.15

                        Label {
                            anchors.centerIn: parent
                            text: vehicleVM.engineTemp.toFixed(0) + "\u00B0"
                            color: vehicleVM.engineTemp > 105 ? root.colorDanger
                                    : vehicleVM.engineTemp > 95 ? root.colorWarning : root.colorSuccess
                            font.pixelSize: 16; font.bold: true
                        }
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("水温"); color: root.colorTextSec; font.pixelSize: 11
                    }
                }
            }
        }
    }
}
