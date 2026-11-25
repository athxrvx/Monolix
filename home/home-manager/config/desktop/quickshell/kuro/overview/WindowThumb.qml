// Single window preview. Uses ScreencopyView (the actual window image);
// if unavailable, show the app icon + name.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config

Rectangle {
    id: root

    required property var client
    required property Item overlay

    signal dragStarted(var client, point pos)
    signal dragMoved(point pos)
    signal dragEnded(point pos)

    readonly property var toplevel: OverviewState.toplevelFor(client.address)
    readonly property string iconName: {
        const e = DesktopEntries.byId(client.cls) ?? DesktopEntries.byId(client.cls.toLowerCase());
        return e?.icon ?? client.cls.toLowerCase();
    }

    radius: Theme.radiusSmall
    color: Theme.surface2
    border.width: mouse.containsMouse ? 2 : 1
    border.color: mouse.containsMouse ? Theme.accent : Theme.border
    clip: true

    // Live preview
    ScreencopyView {
        id: preview
        anchors.fill: parent
        anchors.margins: 1
        captureSource: root.toplevel
        live: Config.overviewLive
        visible: root.toplevel !== null && hasContent
    }

    // Fallback: icon + app name
    Column {
        anchors.centerIn: parent
        spacing: 4
        visible: !preview.visible

        IconImage {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitSize: Math.min(32, root.height * 0.45)
            source: Quickshell.iconPath(root.iconName, true)
            visible: source !== ""
        }
        Text {
            width: root.width - 8
            horizontalAlignment: Text.AlignHCenter
            visible: root.height > 40
            text: root.client.cls || root.client.title
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    // Window title at the bottom on hover
    Rectangle {
        visible: mouse.containsMouse && root.height > 50
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 18
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.85)

        Text {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            verticalAlignment: Text.AlignVCenter
            text: root.client.title
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        property point start
        property bool dragging: false
        property bool draggedThisGesture: false

        onPressed: mouse => {
            start = Qt.point(mouse.x, mouse.y);
            dragging = false;
            draggedThisGesture = false;
        }

        onPositionChanged: mouse => {
            if (!(mouse.buttons & Qt.LeftButton)) return;
            if (!dragging && Math.hypot(mouse.x - start.x, mouse.y - start.y) > 8) {
                dragging = true;
                draggedThisGesture = true;
                root.dragStarted(root.client, mapToItem(root.overlay, mouse.x, mouse.y));
            }
            if (dragging) root.dragMoved(mapToItem(root.overlay, mouse.x, mouse.y));
        }

        onReleased: mouse => {
            if (dragging) {
                dragging = false;
                root.dragEnded(mapToItem(root.overlay, mouse.x, mouse.y));
            }
        }

        onClicked: mouse => {
            if (draggedThisGesture) return;
            if (mouse.button === Qt.MiddleButton) OverviewState.closeWindow(root.client);
            else OverviewState.focusWindow(root.client);
        }
    }
}
