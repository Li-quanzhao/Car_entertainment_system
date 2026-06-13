import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 车辆信息页面 (T10 迭代)
Item {
    id: page

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "\u26FD"
            color: root.colorTextSec
            font.pixelSize: 64
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("车辆信息")
            color: root.colorText
            font.pixelSize: 20
            font.bold: true
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("仪表盘与车辆状态")
            color: root.colorTextSec
            font.pixelSize: 14
        }
    }
}
