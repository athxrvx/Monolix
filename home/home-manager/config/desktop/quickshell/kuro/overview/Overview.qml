// Full-screen overview with a workspace rail and selected-workspace windows.
//   click workspace  : select it; double-click to switch
//   click window     : focus that window
//   drag window      : move it to another workspace
//   middle-click     : close the window
//   ↑ ↓ / 1-9 / Enter: select & enter workspace,  Esc: close

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            readonly property string monName: modelData.name
            readonly property var mon: OverviewState.monitors[monName] ?? { x: 0, y: 0, w: width, h: height, activeWs: -1 }

            // Workspaces shown: those on this monitor + 1..N not used by other monitors
            readonly property var wsList: {
                const own = new Set();
                const elsewhere = new Set();
                for (const w of Hyprland.workspaces.values) {
                    if (w.id <= 0) continue;
                    if (w.monitor && w.monitor.name === monName) own.add(w.id);
                    else elsewhere.add(w.id);
                }
                for (let i = 1; i <= Config.overviewWorkspaces; i++)
                    if (!elsewhere.has(i)) own.add(i);
                return Array.from(own).sort((a, b) => a - b);
            }

            property int selected: mon.activeWs
            property var dragging: null       // client currently being dragged
            property point dragPos: Qt.point(0, 0)

            readonly property real aspect: mon.w / Math.max(1, mon.h)
            readonly property var windowList: OverviewState.windowsOn(selected)
            readonly property real gap: 24
            readonly property real railWidth: 190
            readonly property int cols: Math.max(1, Math.min(3, Math.max(1, windowList.length),
                Math.floor((width - railWidth - 112 + gap) / (420 + gap))))
            readonly property int rows: Math.ceil(windowList.length / cols)
            readonly property real tileW: Math.max(180, Math.min(
                windowList.length === 1 ? 640 : 500,
                (width - railWidth - 112 - (cols - 1) * gap) / cols))
            readonly property real tileH: Math.max(100, Math.min(tileW / aspect,
                (height - 150 - Math.max(0, rows - 1) * gap) / Math.max(1, rows)))

            screen: modelData
            visible: OverviewState.shown
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-overview"
            // Only the currently focused monitor receives keyboard input
            readonly property bool focused: Hyprland.focusedMonitor?.name === monName
            WlrLayershell.keyboardFocus: visible && focused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onVisibleChanged: if (visible) { selected = mon.activeWs; body.forceActiveFocus(); intro.restart(); }

            function step(d) {
                const i = wsList.indexOf(selected);
                selected = wsList[Math.max(0, Math.min(wsList.length - 1, (i < 0 ? 0 : i) + d))];
            }

            Rectangle {
                id: body
                anchors.fill: parent
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.18)
                focus: true

                Keys.onPressed: event => {
                    const k = event.key;
                    if (k === Qt.Key_Escape) OverviewState.close();
                    else if (k === Qt.Key_Left || k === Qt.Key_H || k === Qt.Key_Up || k === Qt.Key_K) win.step(-1);
                    else if (k === Qt.Key_Right || k === Qt.Key_L || k === Qt.Key_Down || k === Qt.Key_J) win.step(1);
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) OverviewState.goTo(win.selected);
                    else if (k >= Qt.Key_1 && k <= Qt.Key_9) OverviewState.goTo(k - Qt.Key_0);
                    else return;
                    event.accepted = true;
                }

                // Click empty area = close
                MouseArea {
                    anchors.fill: parent
                    onClicked: OverviewState.close()
                }

                Rectangle {
                    id: railSurface
                    x: 0
                    y: 0
                    width: win.railWidth + 58
                    height: parent.height
                    color: Theme.bg
                    border.width: 1
                    border.color: Theme.border
                    z: 1
                }

                RowLayout {
                    id: tabs
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: 30
                    anchors.topMargin: 12
                    spacing: 20
                    z: 2

                    Item {
                        implicitWidth: workspaceTabLabel.implicitWidth
                        implicitHeight: 24
                        Text {
                            id: workspaceTabLabel
                            anchors.top: parent.top
                            text: "Workspaces"
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            color: Theme.accent
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {}
                        }
                    }

                    Item {
                        implicitWidth: applicationsTabLabel.implicitWidth
                        implicitHeight: 24
                        Text {
                            id: applicationsTabLabel
                            anchors.top: parent.top
                            text: "Applications"
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: 13
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                OverviewState.close();
                                Launcher.toggle();
                            }
                        }
                    }
                }

                ParallelAnimation {
                    id: intro
                    NumberAnimation { target: overviewLayout; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { target: overviewLayout; property: "scale"; from: 0.98; to: 1; duration: 220; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    id: overviewLayout
                    anchors.fill: parent
                    anchors.leftMargin: 34
                    anchors.rightMargin: 34
                    anchors.topMargin: 58
                    anchors.bottomMargin: 24
                    spacing: 30
                    z: 2

                    ColumnLayout {
                        id: workspaceRail
                        width: win.railWidth
                        Layout.minimumWidth: win.railWidth
                        Layout.preferredWidth: win.railWidth
                        Layout.maximumWidth: win.railWidth
                        Layout.fillHeight: true
                        Layout.fillWidth: false
                        spacing: 8

                        Repeater {
                            id: workspaceItems
                            model: win.wsList

                            Rectangle {
                                id: workspaceEntry
                                required property int modelData
                                readonly property bool current: win.mon.activeWs === modelData
                                readonly property bool chosen: win.selected === modelData
                                readonly property int windowCount: OverviewState.windowsOn(modelData).length
                                Layout.minimumWidth: win.railWidth
                                Layout.fillWidth: true
                                Layout.maximumWidth: win.railWidth
                                Layout.preferredHeight: 96
                                radius: Theme.radiusSmall
                                color: chosen ? Theme.surface : "transparent"
                                border.width: win.dragging !== null && win.hoveredWs === modelData ? 1 : 0
                                border.color: Theme.rose
                                Behavior on color { ColorAnimation { duration: 120 } }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    spacing: 4

                                    Rectangle {
                                        id: workspacePreview
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.minimumWidth: win.railWidth - 10
                                        Layout.maximumWidth: win.railWidth - 10
                                        Layout.preferredWidth: win.railWidth - 10
                                        color: Theme.bgAlt
                                        border.width: 1
                                        border.color: workspaceEntry.current ? Theme.accent : Theme.border
                                        clip: true

                                        Repeater {
                                            model: OverviewState.windowsOn(workspaceEntry.modelData)

                                            Rectangle {
                                                required property var modelData
                                                x: (modelData.x - win.mon.x) * workspacePreview.width / Math.max(1, win.mon.w)
                                                y: (modelData.y - win.mon.y) * workspacePreview.height / Math.max(1, win.mon.h)
                                                width: Math.max(5, modelData.w * workspacePreview.width / Math.max(1, win.mon.w))
                                                height: Math.max(4, modelData.h * workspacePreview.height / Math.max(1, win.mon.h))
                                                color: Theme.surface2
                                                border.width: 1
                                                border.color: workspaceEntry.chosen ? Theme.accent : Theme.border
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: workspaceEntry.windowCount === 0
                                            text: "+"
                                            color: Theme.muted
                                            font.family: Theme.font
                                            font.pixelSize: 18
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "Workspace " + workspaceEntry.modelData
                                            color: workspaceEntry.chosen ? Theme.text : Theme.subtext
                                            font.family: Theme.font
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: String(workspaceEntry.windowCount)
                                            color: Theme.muted
                                            font.family: Theme.font
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                HoverHandler {
                                    onHoveredChanged: if (hovered && win.dragging === null)
                                        win.selected = workspaceEntry.modelData
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.selected = workspaceEntry.modelData
                                    onDoubleClicked: OverviewState.goTo(workspaceEntry.modelData)
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            Layout.fillWidth: true
                            text: "↑ ↓ select   ↵ switch"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 10
                            wrapMode: Text.Wrap
                        }
                    }

                    ColumnLayout {
                        id: mainContent
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 24

                        RowLayout {
                            Layout.fillWidth: true

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: "WORKSPACE " + win.selected
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                                Text {
                                    text: win.windowList.length === 1 ? "1 open window" : win.windowList.length + " open windows"
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                }
                            }
                            Text {
                                text: "DRAG WINDOWS TO MOVE"
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 10
                                font.letterSpacing: 1
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Grid {
                                id: grid
                                anchors.centerIn: parent
                                columns: win.cols
                                spacing: win.gap
                                opacity: 1
                                width: columns * win.tileW + Math.max(0, columns - 1) * spacing

                                Repeater {
                                    id: windows
                                    model: win.windowList

                                    WindowThumb {
                                        required property var modelData
                                        client: modelData
                                        width: win.tileW
                                        height: win.tileH
                                        overlay: body
                                        onDragStarted: (c, p) => {
                                            win.dragging = c;
                                            win.dragPos = p;
                                        }
                                        onDragMoved: p => win.dragPos = p
                                        onDragEnded: p => {
                                            win.dragPos = p;
                                            const targetWs = win.hoveredWs;
                                            const client = win.dragging;
                                            win.dragging = null;
                                            if (client && targetWs > 0)
                                                OverviewState.moveWindow(client, targetWs);
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                visible: win.windowList.length === 0
                                spacing: 10
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "+"
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 42
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "No open windows"
                                    color: Theme.subtext
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "click a window to focus  ·  middle-click to close  ·  esc to dismiss"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // "Ghost" of the dragged window
                Rectangle {
                    visible: win.dragging !== null
                    x: win.dragPos.x - width / 2
                    y: win.dragPos.y - height / 2
                    width: 140
                    height: 34
                    radius: Theme.radiusSmall
                    color: Theme.accent
                    opacity: 0.92

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: win.dragging ? (win.dragging.cls || win.dragging.title) : ""
                        color: Theme.accentFg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                }
            }

            // Workspace under the cursor while dragging
            readonly property int hoveredWs: {
                if (dragging === null) return -1;
                for (let i = 0; i < workspaceItems.count; i++) {
                    const t = workspaceItems.itemAt(i);
                    if (!t) continue;
                    const p = t.mapFromItem(body, dragPos.x, dragPos.y);
                    if (p.x >= 0 && p.y >= 0 && p.x <= t.width && p.y <= t.height) return t.modelData;
                }
                return -1;
            }
        }
    }
}
