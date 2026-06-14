import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 系统设置页面
Item {
    id: page
    anchors.fill: parent

    Flickable {
        anchors.fill: parent
        contentHeight: contentLayout.implicitHeight + 32
        clip: true

        ScrollBar.vertical: ScrollBar {
            active: true
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: contentLayout
            anchors {
                left: parent.left
                right: parent.right
                margins: 16
            }
            spacing: 16

            // 标题
            Label {
                Layout.topMargin: 8
                text: qsTr("系统设置")
                color: root.colorText
                font.pixelSize: 20
                font.bold: true
            }

            // ============================================================
            // 主题设置
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: root.colorSurface
                radius: 12

                RowLayout {
                    anchors {
                        fill: parent
                        margins: 16
                    }
                    spacing: 16

                    Label {
                        text: "\uD83C\uDF19"
                        font.pixelSize: 28
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: qsTr("主题模式")
                            color: root.colorText
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Label {
                            text: qsTr("深色 / 浅色")
                            color: root.colorTextSec
                            font.pixelSize: 11
                        }
                    }

                    ComboBox {
                        id: themeCombo
                        model: settingsVM.themes
                        currentIndex: settingsVM.theme === "light" ? 1 : 0
                        font.pixelSize: 13

                        onActivated: settingsVM.setTheme(currentText)

                        background: Rectangle {
                            radius: 6
                            color: root.colorBg
                            border.color: root.colorSeparator
                        }
                        contentItem: Label {
                            text: settingsVM.theme === "light" ? qsTr("浅色") : qsTr("深色")
                            color: root.colorText
                            font: themeCombo.font
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                        }

                        delegate: ItemDelegate {
                            width: themeCombo.width
                            text: modelData === "light" ? qsTr("浅色") : qsTr("深色")
                            font: themeCombo.font

                            contentItem: Label {
                                text: parent.text
                                color: root.colorText
                                font: parent.font
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? root.colorSeparator : root.colorSurface
                            }
                        }
                    }
                }
            }

            // ============================================================
            // 语言设置
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: root.colorSurface
                radius: 12

                RowLayout {
                    anchors {
                        fill: parent
                        margins: 16
                    }
                    spacing: 16

                    Label {
                        text: "\uD83C\uDF10"
                        font.pixelSize: 28
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: qsTr("语言")
                            color: root.colorText
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Label {
                            text: qsTr("中文 / English")
                            color: root.colorTextSec
                            font.pixelSize: 11
                        }
                    }

                    ComboBox {
                        id: langCombo
                        model: settingsVM.languages
                        currentIndex: settingsVM.language === "en" ? 1 : 0
                        font.pixelSize: 13

                        onActivated: settingsVM.setLanguage(currentText)

                        background: Rectangle {
                            radius: 6
                            color: root.colorBg
                            border.color: root.colorSeparator
                        }
                        contentItem: Label {
                            text: settingsVM.language === "en" ? "English" : "中文"
                            color: root.colorText
                            font: langCombo.font
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                        }

                        delegate: ItemDelegate {
                            width: langCombo.width
                            text: modelData
                            font: langCombo.font

                            contentItem: Label {
                                text: parent.text
                                color: root.colorText
                                font: parent.font
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? root.colorSeparator : root.colorSurface
                            }
                        }
                    }
                }
            }

            // ============================================================
            // 音量设置
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: root.colorSurface
                radius: 12

                RowLayout {
                    anchors {
                        fill: parent
                        margins: 16
                    }
                    spacing: 16

                    Label {
                        text: "\uD83D\uDD0A"
                        font.pixelSize: 28
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: qsTr("系统音量")
                            color: root.colorText
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Label {
                            text: Math.round(settingsVM.volume * 100) + "%"
                            color: root.colorTextSec
                            font.pixelSize: 11
                        }
                    }

                    Slider {
                        id: volumeSlider
                        Layout.fillWidth: true
                        Layout.maximumWidth: 160
                        from: 0
                        to: 100
                        value: settingsVM.volume * 100
                        onMoved: settingsVM.setVolume(value / 100)

                        background: Rectangle {
                            implicitHeight: 4
                            radius: 2
                            color: root.colorSeparator
                            Rectangle {
                                width: volumeSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: root.colorPrimary
                            }
                        }
                        handle: Rectangle {
                            x: volumeSlider.visualPosition
                               * (volumeSlider.availableWidth - width)
                            y: (volumeSlider.availableHeight - height) / 2
                            width: 14
                            height: 14
                            radius: 7
                            color: root.colorPrimary
                        }
                    }
                }
            }

            // ============================================================
            // 系统信息
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: root.colorSurface
                radius: 12

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 16
                    }
                    spacing: 4

                    Label {
                        text: qsTr("关于")
                        color: root.colorText
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Label {
                        text: qsTr("Car Entertainment System")
                        color: root.colorTextSec
                        font.pixelSize: 12
                    }
                    Label {
                        text: qsTr("版本 1.0.0 | Qt 6.11.1 | C++17")
                        color: root.colorTextSec
                        font.pixelSize: 11
                    }
                    Label {
                        text: qsTr("MinGW 16.1.0 | Windows")
                        color: root.colorTextSec
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
