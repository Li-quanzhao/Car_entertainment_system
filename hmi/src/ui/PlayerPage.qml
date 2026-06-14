import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 音乐播放器 — 渐变科技风
Item {
    id: page
    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 20

        // ============================================================
        // 左侧：歌曲列表
        // ============================================================
        SciFiCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.35
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    Layout.leftMargin: 16
                    Layout.bottomMargin: 10
                    text: qsTr("播放列表")
                    color: root.colorPrimary
                    font.pixelSize: 14
                    font.bold: true
                    opacity: 0.85
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.colorSeparator
                }

                ListView {
                    id: songList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: playerVM.playlist
                    clip: true
                    currentIndex: -1
                    highlightMoveDuration: 0

                    delegate: Item {
                        width: ListView.view.width
                        height: 52

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 8
                            color: ListView.isCurrentItem
                                   ? root.colorPrimary : "transparent"
                            opacity: ListView.isCurrentItem ? 0.1 : 0
                        }

                        ColumnLayout {
                            anchors {
                                left: parent.left; leftMargin: 16
                                right: parent.right; rightMargin: 16
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 2

                            Label {
                                text: modelData.title || ""
                                color: ListView.isCurrentItem
                                       ? root.colorPrimary : root.colorText
                                font.pixelSize: 14
                                font.bold: ListView.isCurrentItem
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Label {
                                text: modelData.artist || ""
                                color: root.colorTextSec
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                songList.currentIndex = index
                                playerVM.playIndex(index)
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width - 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 1
                            color: root.colorSeparator
                            opacity: 0.5
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: true; policy: ScrollBar.AsNeeded
                    }
                }
            }
        }

        // ============================================================
        // 右侧：播放区
        // ============================================================
        SciFiCard {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 28
                }
                spacing: 12

                Item { Layout.fillHeight: true }

                // 专辑封面 — 发光圆环
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    width: 140; height: 140

                    // 外发光环
                    Rectangle {
                        anchors.centerIn: parent
                        width: 130; height: 130
                        radius: 65
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.gradCyan }
                            GradientStop { position: 0.5; color: root.gradBlue }
                            GradientStop { position: 1.0; color: root.gradPurple }
                        }
                        opacity: 0.25

                        RotationAnimation on rotation {
                            from: 0; to: 360
                            duration: 8000
                            loops: Animation.Infinite
                            running: playerVM.playing
                        }
                    }

                    // 封面圆
                    Rectangle {
                        anchors.centerIn: parent
                        width: 110; height: 110
                        radius: 55
                        color: root.colorPrimary
                        opacity: 0.08

                        Label {
                            anchors.centerIn: parent
                            text: "\u266B"
                            color: root.colorPrimary
                            font.pixelSize: 44
                            opacity: 0.7
                        }
                    }
                }

                // 歌曲信息
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    text: playerVM.title || qsTr("未选择歌曲")
                    color: root.colorText
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: playerVM.artist || ""
                    color: root.colorPrimary
                    font.pixelSize: 13
                    opacity: 0.7
                }

                Item { Layout.preferredHeight: 10 }

                // 渐变进度条
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: formatTime(playerVM.position)
                        color: root.colorTextSec
                        font.pixelSize: 11
                        font.family: "monospace"
                    }

                    Slider {
                        id: progressSlider
                        Layout.fillWidth: true
                        from: 0
                        to: Math.max(1, playerVM.duration)
                        value: playerVM.position
                        live: false
                        onMoved: playerVM.setPosition(value)

                        background: Rectangle {
                            implicitHeight: 4
                            radius: 2
                            color: root.colorSeparator

                            // 渐变进度填充
                            Rectangle {
                                width: progressSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: root.gradCyan }
                                    GradientStop { position: 1.0; color: root.gradPurple }
                                }
                            }

                            // 当前点光晕
                            Rectangle {
                                x: progressSlider.visualPosition * (parent.width - 8)
                                y: -4
                                width: 8; height: 8
                                radius: 4
                                color: root.colorPrimary
                                opacity: 0.6
                            }
                        }
                        handle: Rectangle {
                            x: progressSlider.visualPosition
                               * (progressSlider.availableWidth - width)
                            y: (progressSlider.availableHeight - height) / 2
                            width: 14; height: 14
                            radius: 7
                            color: root.colorPrimary
                            visible: progressSlider.pressed
                        }
                    }

                    Label {
                        text: formatTime(playerVM.duration)
                        color: root.colorTextSec
                        font.pixelSize: 11
                        font.family: "monospace"
                    }
                }

                Item { Layout.preferredHeight: 8 }

                // 播放控制按钮 — 霓虹风格
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20

                    // 上一首
                    Item {
                        implicitWidth: 44; implicitHeight: 44

                        Rectangle {
                            anchors.fill: parent
                            radius: 22
                            color: "transparent"
                            border.color: root.colorTextSec
                            border.width: 1
                            opacity: mousePrev.containsMouse ? 0.5 : 0.25
                        }
                        Label {
                            anchors.centerIn: parent
                            text: "\u23EE"
                            color: root.colorTextSec
                            font.pixelSize: 18
                            opacity: mousePrev.containsMouse ? 1 : 0.6
                        }
                        MouseArea {
                            id: mousePrev
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: playerVM.previous()
                        }
                    }

                    // 播放/暂停 — 渐变发光
                    Item {
                        implicitWidth: 60; implicitHeight: 60

                        Rectangle {
                            anchors.fill: parent
                            radius: 30
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: root.gradCyan }
                                GradientStop { position: 1.0; color: root.gradBlue }
                            }
                        }
                        // 发光外圈
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -3
                            radius: 33
                            color: "transparent"
                            border.color: root.colorPrimary
                            border.width: 2
                            opacity: 0.3
                        }
                        Label {
                            anchors.centerIn: parent
                            text: playerVM.playing ? "\u23F8" : "\u25B6"
                            color: "white"
                            font.pixelSize: 24
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                playerVM.playing ? playerVM.pause() : playerVM.play()
                            }
                        }
                    }

                    // 下一首
                    Item {
                        implicitWidth: 44; implicitHeight: 44

                        Rectangle {
                            anchors.fill: parent
                            radius: 22
                            color: "transparent"
                            border.color: root.colorTextSec
                            border.width: 1
                            opacity: mouseNext.containsMouse ? 0.5 : 0.25
                        }
                        Label {
                            anchors.centerIn: parent
                            text: "\u23ED"
                            color: root.colorTextSec
                            font.pixelSize: 18
                            opacity: mouseNext.containsMouse ? 1 : 0.6
                        }
                        MouseArea {
                            id: mouseNext
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: playerVM.next()
                        }
                    }
                }

                // 音量控制
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: 200
                    Layout.topMargin: 12
                    spacing: 10

                    Label {
                        text: "\uD83D\uDD0A"
                        color: root.colorTextSec
                        font.pixelSize: 15
                        opacity: 0.6
                    }

                    Slider {
                        id: volumeSlider
                        Layout.fillWidth: true
                        from: 0; to: 100
                        value: playerVM.volume * 100
                        onMoved: playerVM.setVolume(value / 100)

                        background: Rectangle {
                            implicitHeight: 4; radius: 2
                            color: root.colorSeparator
                            Rectangle {
                                width: volumeSlider.visualPosition * parent.width
                                height: parent.height; radius: 2
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: root.gradPurple }
                                    GradientStop { position: 1.0; color: root.gradPink }
                                }
                            }
                        }
                        handle: Rectangle {
                            x: volumeSlider.visualPosition
                               * (volumeSlider.availableWidth - width)
                            y: (volumeSlider.availableHeight - height) / 2
                            width: 12; height: 12; radius: 6
                            color: root.gradPurple
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    function formatTime(ms) {
        var sec = Math.floor(ms / 1000)
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }
}
