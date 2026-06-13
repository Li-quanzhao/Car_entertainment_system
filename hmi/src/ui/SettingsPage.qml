import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 系统设置页面 (T11 迭代)
Item {
    id: page

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "\u2699"
            color: root.colorTextSec
            font.pixelSize: 64
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("系统设置")
            color: root.colorText
            font.pixelSize: 20
            font.bold: true
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("主题、语言、音量")
            color: root.colorTextSec
            font.pixelSize: 14
        }
    }
}
