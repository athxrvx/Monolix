// Hyprland workspaces, GNOME-style: a compact row of dots where the active
// workspace becomes a short pill. Workspaces 1..persistent are always shown,
// plus any other workspaces on this monitor.
//   numerals: "" = dots, "kanji" = 一 二 三, "roman" = I II III
// Click = switch, right-click = workspace overview, scroll = next/previous.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.overview

RowLayout {
    id: root

    required property var monitor
    property string numerals: ""
    property int persistent: 5
    property int itemHeight: 20

    readonly property var kanji: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    readonly property var roman: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

    readonly property var hyprMonitor: Hyprland.monitorFor(monitor)
    readonly property int activeId: hyprMonitor?.activeWorkspace?.id ?? -1
    readonly property var existing: Hyprland.workspaces.values.filter(w => w.id > 0)

    readonly property var ids: {
        const s = new Set();
        for (let i = 1; i <= persistent; i++) s.add(i);
        for (const w of existing)
            if (w.monitor && w.monitor.name === root.monitor.name) s.add(w.id);
        return Array.from(s).sort((a, b) => a - b);
    }

    function label(id) {
        if (numerals === "kanji" && id <= 10) return kanji[id - 1];
        if (numerals === "roman" && id <= 10) return roman[id - 1];
        return String(id);
    }

    spacing: root.numerals === "" ? 8 : 4

    Repeater {
        model: root.ids

        Rectangle {
            id: ws
            required property int modelData
            readonly property bool current: modelData === root.activeId
            readonly property bool occupied: root.existing.some(w => w.id === modelData)
            readonly property bool dots: root.numerals === ""

            implicitWidth: dots ? (current ? 24 : 8) : Math.max(root.itemHeight, wsLabel.implicitWidth + 12)
            implicitHeight: dots ? 8 : root.itemHeight
            radius: dots ? 0 : Theme.radiusSmall
            color: dots
                 ? (current ? Theme.accent
                    : occupied ? Theme.subtext : Theme.surface2)
                 : (current ? Theme.accent
                    : mouse.containsMouse ? Theme.surface2
                    : occupied ? Theme.surface : "transparent")

            Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                id: wsLabel
                anchors.centerIn: parent
                visible: !ws.dots
                text: root.label(ws.modelData)
                color: ws.current ? Theme.accentFg : ws.occupied ? Theme.text : Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                // left = switch workspace, right = workspace overview
                onClicked: mouse => mouse.button === Qt.RightButton
                                    ? OverviewState.toggle()
                                    : Hyprland.dispatch("hl.dsp.focus({ workspace = " + ws.modelData + " })")
            }
        }
    }

    WheelHandler {
        onWheel: event => Hyprland.dispatch(event.angleDelta.y > 0
    ? "hl.dsp.focus({ workspace = 'm-1' })"
    : "hl.dsp.focus({ workspace = 'm+1' })")
    }
}
