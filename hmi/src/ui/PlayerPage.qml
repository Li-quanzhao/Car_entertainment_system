import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 音乐播放器页面 (T7)
Item {
    id: page
    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 24

        // ============================================================
        // 左侧：歌曲列表
        // ============================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.35
            color: root.colorSurface
            radius: 12

            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // 列表标题
                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    Layout.leftMargin: 16
                    Layout.bottomMargin: 8
                    text: qsTr("播放列表")
                    color: root.colorText
                    font.pixelSize: 14
                    font.bold: true
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
                            opacity: ListView.isCurrentItem ? 0.15 : 0
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
                            width: parent.width
                            height: 1
                            color: root.colorSeparator
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }
                }
            }
        }

        // ============================================================
        // 右侧：当前播放 + 控制区
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

                // 专辑封面占位
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 120
                    height: 120
                    radius: 12
                    color: root.colorPrimary
                    opacity: 0.15

                    Label {
                        anchors.centerIn: parent
                        text: "\u266B"
                        color: root.colorPrimary
                        font.pixelSize: 48
                    }
                }

                // 歌曲信息
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
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
                    color: root.colorTextSec
                    font.pixelSize: 13
                }

                Item { Layout.preferredHeight: 8 }

                // 进度条
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
                            Rectangle {
                                width: progressSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: root.colorPrimary
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

                // 播放控制按钮
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24

                    // 上一首
                    RoundButton {
                        text: "\u23EE"
                        font.pixelSize: 18
                        implicitWidth: 40; implicitHeight: 40
                        flat: true
                        onClicked: playerVM.previous()
                        contentItem: Label {
                            text: parent.text
                            color: root.colorText
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 20
                            color: parent.hovered ? root.colorSeparator : "transparent"
                        }
                    }

                    // 播放/暂停
                    RoundButton {
                        text: playerVM.playing ? "\u23F8" : "\u25B6"
                        font.pixelSize: 22
                        implicitWidth: 56; implicitHeight: 56
                        onClicked: {
                            if (playerVM.playing)
                                playerVM.pause()
                            else
                                playerVM.play()
                        }
                        contentItem: Label {
                            text: parent.text
                            color: root.colorBg
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 28
                            color: root.colorPrimary
                        }
                    }

                    // 下一首
                    RoundButton {
                        text: "\u23ED"
                        font.pixelSize: 18
                        implicitWidth: 40; implicitHeight: 40
                        flat: true
                        onClicked: playerVM.next()
                        contentItem: Label {
                            text: parent.text
                            color: root.colorText
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 20
                            color: parent.hovered ? root.colorSeparator : "transparent"
                        }
                    }
                }

                // 音量
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: 200
                    spacing: 8

                    Label {
                        text: "\uD83D\uDD0A"
                        color: root.colorTextSec
                        font.pixelSize: 14
                    }

                    Slider {
                        id: volumeSlider
                        Layout.fillWidth: true
                        from: 0; to: 100
                        value: playerVM.volume * 100
                        onMoved: playerVM.setVolume(value / 100)

                        background: Rectangle {
                            implicitHeight: 4
                            radius: 2
                            color: root.colorSeparator
                            Rectangle {
                                width: volumeSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: root.colorAccent
                            }
                        }
                        handle: Rectangle {
                            x: volumeSlider.visualPosition
                               * (volumeSlider.availableWidth - width)
                            y: (volumeSlider.availableHeight - height) / 2
                            width: 12; height: 12
                            radius: 6
                            color: root.colorAccent
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    // 时间格式化工具函数
    function formatTime(ms) {
        var sec = Math.floor(ms / 1000)
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }
}
