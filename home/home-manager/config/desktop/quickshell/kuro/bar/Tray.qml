// System tray (StatusNotifierItem): Discord, OBS, Steam, nm-applet, etc.
//   left-click   = open app (if the item only has a menu, the menu opens)
//   right-click  = app menu
//   middle-click = secondary action (app-dependent)
//   scroll       = forwarded to the app (e.g. volume in some applets)

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config

RowLayout {
    id: root

    required property var window     // bar PanelWindow, where the menu is attached

    spacing: 8

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item
            required property SystemTrayItem modelData

            implicitWidth: 16
            implicitHeight: 16
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            function openMenu() {
                if (!modelData.hasMenu) return;
                // Menu position: right below the icon, relative to the bar window
                const p = item.mapToItem(null, 0, 0);
                menu.anchor.rect.x = p.x;
                menu.anchor.rect.y = p.y;
                menu.anchor.rect.width = item.width;
                menu.anchor.rect.height = item.height + Theme.popupGap;
                menu.open();
            }

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) openMenu();
                else if (mouse.button === Qt.MiddleButton) modelData.secondaryActivate();
                else if (modelData.onlyMenu) openMenu();
                else modelData.activate();
            }

            onWheel: wheel => {
                const horizontal = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y);
                modelData.scroll(horizontal ? wheel.angleDelta.x : wheel.angleDelta.y, horizontal);
            }

            // The app's own menu, rendered by Quickshell as a popup below the icon
            QsMenuAnchor {
                id: menu
                menu: item.modelData.menu
                anchor.window: root.window
                anchor.edges: Edges.Bottom | Edges.Left
                anchor.gravity: Edges.Bottom | Edges.Right
            }

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
            }
        }
    }
}
