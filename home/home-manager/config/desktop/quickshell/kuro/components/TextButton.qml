// Small outlined text button. `primary` = accent-colored block.

import QtQuick
import qs.config

Rectangle {
    id: root

    property string text: ""
    property bool primary: false
    property bool sharp: false

    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    radius: root.sharp ? 0 : Theme.radiusSmall
    color: primary ? Theme.accent : (mouse.containsMouse ? Theme.surface2 : "transparent")
    border.color: primary ? Theme.accent : Theme.border
    opacity: enabled ? 1 : 0.4
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.primary ? Theme.accentFg : Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
        font.letterSpacing: 0.5
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
