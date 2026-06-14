import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// AI 助手对话页面 — 渐变科技风
Item {
    id: page

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // 连接状态提示
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 28
            color: "#ff4466"; opacity: 0.9
            visible: !agentVM.connected

            Label {
                anchors.centerIn: parent
                text: qsTr("Agent 服务未连接，请确保 Server 已启动")
                color: "white"; font.pixelSize: 12
            }
        }

        // 消息列表
        ListView {
            id: messageList
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.topMargin: 8; Layout.bottomMargin: 8
            clip: true; spacing: 8; boundsBehavior: Flickable.StopAtBounds

            model: agentVM.messages

            delegate: Item {
                width: ListView.view.width
                height: bubbleCol.height + 24

                Column {
                    id: bubbleCol
                    anchors {
                        right: modelData.role === "user" ? parent.right : undefined
                        left: modelData.role === "user" ? undefined : parent.left
                        margins: 16
                    }
                    width: Math.min(parent.width * 0.78, 420)
                    spacing: 4

                    Label {
                        anchors.right: modelData.role === "user" ? parent.right : undefined
                        anchors.left: modelData.role === "user" ? undefined : parent.left
                        text: modelData.role === "user" ? qsTr("你") :
                              modelData.role === "assistant" ? qsTr("AI 助手") : qsTr("错误")
                        color: modelData.role === "error" ? root.colorDanger : root.colorTextSec
                        font.pixelSize: 11
                        visible: modelData.role !== "error"
                    }

                    Rectangle {
                        width: parent.width
                        height: textLabel.implicitHeight + 24
                        radius: 10
                        color: modelData.role === "user" ? root.colorPrimary :
                               modelData.role === "error" ? root.colorDanger :
                               root.colorSurface
                        opacity: modelData.role === "error" ? 0.9 : 1.0

                        // AI 回复气泡发光边框
                        Rectangle {
                            anchors.fill: parent; anchors.margins: -1; radius: 11
                            color: "transparent"
                            border.color: root.colorPrimary
                            border.width: 1; opacity: 0.08
                            visible: modelData.role === "assistant"
                        }

                        Label {
                            id: textLabel
                            x: 12; y: 12; width: parent.width - 24
                            text: modelData.text || ""
                            color: modelData.role === "user" ? "#ffffff" : root.colorText
                            font.pixelSize: 14; wrapMode: Text.WordWrap
                            textFormat: Text.PlainText
                        }
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                text: qsTr("开始和 AI 助手对话吧")
                color: root.colorTextSec; font.pixelSize: 16
                visible: agentVM.messages.length === 0 && !agentVM.thinking
            }

            Connections {
                target: agentVM
                function onMessagesChanged() {
                    Qt.callLater(function() { messageList.positionViewAtEnd() })
                }
            }
        }

        // 思考中
        RowLayout {
            Layout.fillWidth: true; Layout.leftMargin: 16; Layout.bottomMargin: 4
            spacing: 8; visible: agentVM.thinking

            Label {
                text: "\u25CF \u25CF \u25CF"; color: root.colorPrimary
                font.pixelSize: 16; opacity: 0.6
            }
            Label {
                text: qsTr("AI 正在思考..."); color: root.colorTextSec; font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }
        }

        // 输入区域
        SciFiCard {
            Layout.fillWidth: true; Layout.preferredHeight: 56
            height: 56

            RowLayout {
                anchors { fill: parent; margins: 8 }
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    radius: 8; color: root.colorBg
                    border.color: root.colorSeparator; border.width: 1

                    TextInput {
                        id: inputField
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                        color: root.colorText; font.pixelSize: 14
                        verticalAlignment: TextInput.AlignVCenter; clip: true
                        enabled: !agentVM.thinking
                    }

                    Text {
                        anchors.fill: parent; anchors.leftMargin: 12
                        text: qsTr("输入消息..."); color: root.colorTextSec
                        font.pixelSize: 14; verticalAlignment: Text.AlignVCenter
                        visible: !inputField.text
                    }
                }

                Rectangle {
                    implicitWidth: 48; implicitHeight: 36; radius: 8
                    gradient: Gradient {
                        GradientStop { position: 0; color: root.gradCyan }
                        GradientStop { position: 1; color: root.gradBlue }
                    }
                    opacity: inputField.text.trim().length > 0 && !agentVM.thinking ? 1 : 0.3

                    Label {
                        anchors.centerIn: parent
                        text: "\u27A4"; color: "white"; font.pixelSize: 18
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: inputField.text.trim().length > 0 && !agentVM.thinking
                        onClicked: {
                            agentVM.sendMessage(inputField.text)
                            inputField.text = ""
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 36; implicitHeight: 36; radius: 8
                    color: mouseClear.containsMouse ? root.colorSeparator : "transparent"
                    visible: agentVM.messages.length > 0

                    Label {
                        anchors.centerIn: parent
                        text: "\u2716"; color: root.colorTextSec; font.pixelSize: 14
                    }
                    MouseArea {
                        id: mouseClear; anchors.fill: parent; hoverEnabled: true
                        onClicked: agentVM.clearMessages()
                    }
                }
            }
        }
    }
}
