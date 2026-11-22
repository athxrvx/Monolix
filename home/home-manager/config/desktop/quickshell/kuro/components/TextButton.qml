// Small outlined text button. `primary` = accent-colored block.

import QtQuick
import qs.config

Rectangle {
    id: root

    property string text: ""
    property bool primary: false
    property bool sharp: false
    property bool flat: false

    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    radius: root.sharp ? 0 : Theme.radiusSmall
    color: flat ? (mouse.containsMouse ? Theme.surface2 : "transparent")
        : primary ? Theme.accent : (mouse.containsMouse ? Theme.surface2 : "transparent")
    border.color: flat ? "transparent" : primary ? Theme.accent : Theme.border
    opacity: enabled ? 1 : 0.4
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.primary ? (root.flat ? Theme.accent : Theme.accentFg) : Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
        font.letterSpacing: 0.5
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        color: Theme.accent
        visible: root.flat && root.primary
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
