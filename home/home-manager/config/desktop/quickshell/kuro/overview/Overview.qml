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

            readonly property var windowList: OverviewState.windowsOn(selected)
            readonly property real railWidth: 270
            // Keep the overview clear of the top panel and bottom dock.
            readonly property real topInset: 30
            readonly property real bottomInset: 48

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
                color: "transparent"
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

                Rectangle {
                    id: backdrop
                    x: 0
                    y: win.topInset
                    width: parent.width
                    height: Math.max(0, parent.height - win.topInset - win.bottomInset)
                    color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.18)

                    // Click empty area = close
                    MouseArea {
                        anchors.fill: parent
                        onClicked: OverviewState.close()
                    }
                }

                Rectangle {
                    id: railSurface
                    x: 8
                    y: win.topInset + 8
                    width: win.railWidth + 10
                    height: Math.max(0, parent.height - win.topInset - win.bottomInset - 16)
                    color: Theme.bg
                    border.width: 1
                    border.color: Theme.border
                    z: 1
                }

                ParallelAnimation {
                    id: intro
                    NumberAnimation { target: overviewLayout; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { target: overviewLayout; property: "scale"; from: 0.98; to: 1; duration: 220; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    id: overviewLayout
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.topMargin: win.topInset + 8
                    anchors.bottomMargin: win.bottomInset + 8
                    spacing: 12
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
                                Layout.preferredHeight: (win.railWidth - 20) * 9 / 16 + 10
                                radius: Theme.radiusSmall
                                color: chosen ? Theme.surface : "transparent"
                                border.width: win.dragging !== null && win.hoveredWs === modelData ? 1 : 0
                                border.color: Theme.rose
                                Behavior on color { ColorAnimation { duration: 120 } }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    spacing: 0

                                    Rectangle {
                                        id: workspacePreview
                                        Layout.fillWidth: true
                                        Layout.fillHeight: false
                                        Layout.minimumWidth: win.railWidth - 20
                                        Layout.maximumWidth: win.railWidth - 20
                                        Layout.preferredWidth: win.railWidth - 20
                                        Layout.minimumHeight: (win.railWidth - 20) * 9 / 16
                                        Layout.maximumHeight: (win.railWidth - 20) * 9 / 16
                                        Layout.preferredHeight: (win.railWidth - 20) * 9 / 16
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

                    }

                    Item {
                        id: mainContent
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        readonly property real previewScale: Math.min(
                            (width - 24) / Math.max(1, win.mon.w),
                            (height - 24) / Math.max(1, win.mon.h))
                        readonly property real previewWidth: win.mon.w * previewScale
                        readonly property real previewHeight: win.mon.h * previewScale

                        Repeater {
                            id: windows
                            model: win.windowList

                            WindowThumb {
                                required property var modelData
                                client: modelData
                                x: (mainContent.width - mainContent.previewWidth) / 2
                                    + (modelData.x - win.mon.x) * mainContent.previewScale
                                y: (mainContent.height - mainContent.previewHeight) / 2
                                    + (modelData.y - win.mon.y) * mainContent.previewScale
                                width: modelData.w * mainContent.previewScale
                                height: modelData.h * mainContent.previewScale
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
