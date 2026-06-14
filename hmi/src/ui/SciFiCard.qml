import QtQuick

// 发光卡片 — 全站复用
Rectangle {
    color: root.colorSurface
    radius: 14

    // 发光边框
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: parent.radius + 1
        color: "transparent"
        border.color: root.colorPrimary
        border.width: 1
        opacity: 0.1
    }

    // 顶部高光线
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: root.colorPrimary
        opacity: 0.06
    }
}
