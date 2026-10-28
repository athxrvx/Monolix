import QtQuick
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: 128
    implicitHeight: 128

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Colours.palette.m3primaryContainer
        border.width: Math.max(1, root.width * 0.035)
        border.color: Colours.palette.m3outlineVariant

        MaterialIcon {
            anchors.centerIn: parent
            text: "cyclone"
            color: Colours.palette.m3onPrimaryContainer
            fill: 1
            font.pointSize: parent.width * 0.7
        }
    }
}
