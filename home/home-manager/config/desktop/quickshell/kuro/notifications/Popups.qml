// Notification popup window on the currently focused monitor.
// Empty area around the cards is click-through (mask), so windows underneath stay usable.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.bar

PanelWindow {
    id: root

    readonly property bool bottom: Config.notifPosition === "bottom-right"
    readonly property int barOffset: BarState.shown && !bottom
        ? BarState.layout.height + (BarState.layout.margin?.top ?? 0) : 0

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: Notifications.popups.count > 0 && !Notifications.centerOpen

    anchors {
        top: !root.bottom
        bottom: root.bottom
        right: true
    }
    margins {
        top: root.barOffset + Theme.popupGap
        bottom: Theme.popupGap
        right: Theme.popupGap
    }

    implicitWidth: Math.min(Config.notifWidth, 390)
    implicitHeight: list.contentHeight + 8
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"

    mask: Region { item: list.contentItem }

    ListView {
        id: list
        anchors.fill: parent
        spacing: 8
        interactive: false
        verticalLayoutDirection: root.bottom ? ListView.BottomToTop : ListView.TopToBottom
        model: Notifications.popups

        delegate: NotifCard {
            required property int nid
            required property int token
            width: list.width
            notif: Notifications.findEntry(token)
            onExpired: {
                if (notif && notif.transient) Notifications.dismiss(notif);
                else Notifications.hidePopupToken(token);
            }
        }

        add: Transition {
            NumberAnimation {
                property: "x"
                from: root.width
                to: 0
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        remove: Transition {
            NumberAnimation {
                property: "x"
                to: root.width
                duration: 120
                easing.type: Easing.InCubic
            }
        }
    }
}
