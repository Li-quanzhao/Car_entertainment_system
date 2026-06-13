import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// AI 助手对话页面
Item {
    id: page

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ============================================================
        // 连接状态提示
        // ============================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            color: agentVM.connected ? root.colorAccent : "#e06c75"
            opacity: 0.9
            visible: !agentVM.connected

            Label {
                anchors.centerIn: parent
                text: qsTr("Agent 服务未连接，请确保 Server 已启动")
                color: "white"
                font.pixelSize: 12
            }
        }

        // ============================================================
        // 消息列表
        // ============================================================
        ListView {
            id: messageList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds

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

                    // 角色标签
                    Label {
                        anchors.right: modelData.role === "user" ? parent.right : undefined
                        anchors.left: modelData.role === "user" ? undefined : parent.left
                        text: modelData.role === "user" ? qsTr("你") :
                              modelData.role === "assistant" ? qsTr("AI 助手") : qsTr("错误")
                        color: modelData.role === "error" ? "#e06c75" : root.colorTextSec
                        font.pixelSize: 11
                        visible: modelData.role !== "error"
                    }

                    // 气泡
                    Rectangle {
                        width: parent.width
                        height: textLabel.implicitHeight + 24
                        radius: 10
                        color: modelData.role === "user" ? root.colorPrimary :
                               modelData.role === "error" ? "#e06c75" :
                               root.colorSurface
                        opacity: modelData.role === "error" ? 0.9 : 1.0

                        Label {
                            id: textLabel
                            x: 12
                            y: 12
                            width: parent.width - 24
                            text: modelData.text || ""
                            color: modelData.role === "user" ? "#ffffff" : root.colorText
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                            textFormat: Text.PlainText
                        }
                    }
                }
            }

            // 空状态
            Label {
                anchors.centerIn: parent
                text: qsTr("开始和 AI 助手对话吧")
                color: root.colorTextSec
                font.pixelSize: 16
                visible: agentVM.messages.length === 0 && !agentVM.thinking
            }

            // 新消息自动滚动到底部
            Connections {
                target: agentVM
                function onMessagesChanged() {
                    Qt.callLater(function() {
                        messageList.positionViewAtEnd()
                    })
                }
            }
        }

        // ============================================================
        // 思考中指示器
        // ============================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.bottomMargin: 4
            spacing: 8
            visible: agentVM.thinking

            Label {
                text: "\u25CF \u25CF \u25CF"
                color: root.colorPrimary
                font.pixelSize: 16
                opacity: 0.6
            }
            Label {
                text: qsTr("AI 正在思考...")
                color: root.colorTextSec
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }
        }

        // ============================================================
        // 输入区域
        // ============================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: root.colorSurface

            // 顶部分隔线
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: root.colorSeparator
            }

            RowLayout {
                anchors {
                    fill: parent
                    margins: 8
                }
                spacing: 8

                TextField {
                    id: inputField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: qsTr("输入消息...")
                    color: root.colorText
                    placeholderTextColor: root.colorTextSec
                    font.pixelSize: 14
                    clip: true
                    background: Rectangle {
                        radius: 8
                        color: root.colorBg
                        border.color: root.colorSeparator
                        border.width: 1
                    }
                    leftPadding: 12
                    rightPadding: 12
                    verticalAlignment: TextInput.AlignVCenter

                    onAccepted: sendButton.clicked()
                    enabled: !agentVM.thinking
                }

                Button {
                    id: sendButton
                    implicitWidth: 48
                    implicitHeight: 36
                    enabled: inputField.text.trim().length > 0 && !agentVM.thinking

                    contentItem: Label {
                        text: "\u27A4"
                        color: sendButton.enabled ? "white" : root.colorTextSec
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 8
                        color: sendButton.enabled ? root.colorPrimary : root.colorSeparator
                    }

                    onClicked: {
                        agentVM.sendMessage(inputField.text)
                        inputField.text = ""
                        inputField.focus = false
                    }
                }

                // 清空按钮
                Button {
                    implicitWidth: 36
                    implicitHeight: 36
                    visible: agentVM.messages.length > 0

                    contentItem: Label {
                        text: "\u2716"
                        color: root.colorTextSec
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 8
                        color: "transparent"
                    }

                    onClicked: agentVM.clearMessages()
                }
            }
        }
    }
}
