import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

// 导航页面 (T8 迭代)
Item {
    id: page

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "\u2302"
            color: root.colorTextSec
            font.pixelSize: 64
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("导航系统")
            color: root.colorText
            font.pixelSize: 20
            font.bold: true
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("地图与路线规划")
            color: root.colorTextSec
            font.pixelSize: 14
        }
    }
}
