// Bar item: icon + optional label. Left/right click and scroll.

import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property real iconScale: 1.0
    property color iconColor: Theme.text
    property color labelColor: Theme.subtext
    property bool dimmed: false

    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal scrolled(int delta)

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusSmall
    color: mouse.containsMouse ? Theme.surface : "transparent"
    opacity: dimmed ? 0.55 : 1
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: root.icon !== ""
            text: root.icon
            color: root.iconColor
            font.family: Theme.iconFont
            font.pixelSize: (Theme.iconSize - 3) * root.iconScale
        }
        Text {
            visible: root.label !== ""
            Layout.maximumWidth: 140
            text: root.label
            color: root.labelColor
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.rightClicked();
            else if (mouse.button === Qt.MiddleButton) root.middleClicked();
            else root.clicked();
        }
        onWheel: wheel => root.scrolled(wheel.angleDelta.y)
    }
}
