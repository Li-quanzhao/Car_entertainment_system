import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 蓝牙电话页面 (T9 迭代)
Item {
    id: page

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "\u260E"
            color: root.colorTextSec
            font.pixelSize: 64
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("蓝牙电话")
            color: root.colorText
            font.pixelSize: 20
            font.bold: true
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("设备列表与通话")
            color: root.colorTextSec
            font.pixelSize: 14
        }
    }
}
