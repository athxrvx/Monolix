// Top bar, one per monitor. Shape and content come from BarState.layout,
// so changing the layout updates the bar immediately without a restart.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

Scope {
    id: root

    signal openPage(string name)
    signal toggleControl()

    readonly property var lay: BarState.layout
    readonly property var activeModules: [...(lay.left ?? []), ...(lay.center ?? []), ...(lay.right ?? [])]
    property int refreshPhase: 0

    // Refresh only services represented in the active layout. This keeps a
    // minimal bar from spawning nmcli/bluez/audio queries every few seconds.
    function hasModule(name) {
        return activeModules.some(spec => String(spec).split(":")[0] === name);
    }

    // Spread indicator refreshes across the interval to avoid launching every
    // status command at once. Each group still refreshes about every 3 seconds.
    Timer {
        interval: 750
        repeat: true
        running: BarState.shown
        triggeredOnStart: true
        onTriggered: {
            const phase = root.refreshPhase;
            root.refreshPhase = (phase + 1) % 4;
            if (phase === 0) {
                if (root.hasModule("volume") || root.hasModule("mic")) Audio.refresh();
                if (root.hasModule("memory") || root.hasModule("cpu")) SystemStats.refresh();
            } else if (phase === 1) {
                if (root.hasModule("network")) Network.refresh();
                if (root.hasModule("battery")) Battery.refresh();
            } else if (phase === 2) {
                if (root.hasModule("brightness")) Brightness.refresh();
                if (root.hasModule("notification")) Notifications.refresh();
            } else if (root.hasModule("profile")) PowerProfile.refresh();
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            screen: modelData
            visible: BarState.shown
            anchors { top: true; left: true; right: true }
            margins {
                top: root.lay.margin?.top ?? 0
                left: root.lay.margin?.left ?? 0
                right: root.lay.margin?.right ?? 0
            }
            implicitHeight: root.lay.height
            color: "transparent"
            WlrLayershell.namespace: "quickshell-bar"

            // ── Background ("solid" style) ────────────────────────────
            Rectangle {
                anchors.fill: parent
                visible: root.lay.style === "solid"
                color: Theme.bg
                radius: root.lay.radius
                border.width: root.lay.radius > 0 ? 1 : 0
                border.color: Theme.border

                // flatTop: cover the top corners so only the bottom corners are rounded
                Rectangle {
                    visible: root.lay.flatTop === true && root.lay.radius > 0
                    width: parent.width
                    height: parent.radius
                    color: Theme.bg
                }
            }

            // Bottom line for a solid bar with no radius
            Rectangle {
                visible: root.lay.style === "solid" && root.lay.radius === 0
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }

            // ── Left / center / right ─────────────────────────────────
            Section {
                anchors.left: parent.left
                anchors.leftMargin: root.lay.style === "solid" ? 16 : 10
                anchors.verticalCenter: parent.verticalCenter
                specs: root.lay.left
                monitor: win.modelData
                window: win
                layout: root.lay
                onOpenPage: n => root.openPage(n)
                onToggleControl: root.toggleControl()
            }

            Section {
                anchors.centerIn: parent
                visible: !(Config.islandEnabled && root.lay.island === true)
                specs: root.lay.center
                monitor: win.modelData
                window: win
                layout: root.lay
                onOpenPage: n => root.openPage(n)
                onToggleControl: root.toggleControl()
            }

            Section {
                anchors.right: parent.right
                anchors.rightMargin: root.lay.style === "solid" ? 6 : 0
                anchors.verticalCenter: parent.verticalCenter
                specs: root.lay.right
                monitor: win.modelData
                window: win
                layout: root.lay
                onOpenPage: n => root.openPage(n)
                onToggleControl: root.toggleControl()
            }
        }
    }
}
