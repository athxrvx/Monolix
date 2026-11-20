// Notification center panel that drops from the bar (top-right of the focused monitor).
// Toggle: click the bell in the bar, or  qs -c shell ipc call notifications toggle
// Also closes with Esc or a click outside the panel.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.components
import qs.services
import qs.bar

PanelWindow {
    id: root

    readonly property int barOffset: BarState.shown
        ? BarState.layout.height + (BarState.layout.margin?.top ?? 0) : 0
    readonly property int maxHeight: Math.round((screen?.height ?? 900) * 0.75) - barOffset

    property int tick: 0          // refreshes relative time labels ("5m", "1h") while open

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: Notifications.centerOpen || panel.opacity > 0

    anchors { top: true; right: true }
    margins {
        top: root.barOffset + Theme.popupGap
        right: Theme.popupGap
    }

    implicitWidth: Math.min(Config.notifWidth + 48, (screen?.width ?? 1280) - Theme.popupGap * 2)
    implicitHeight: Math.min(root.maxHeight, header.implicitHeight + content.implicitHeight + 36)
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notification-center"
    WlrLayershell.keyboardFocus: Notifications.centerOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Click outside the panel to close
    HyprlandFocusGrab {
        windows: [ root ]
        active: Notifications.centerOpen && root.visible
        onCleared: Notifications.centerOpen = false
    }

    Timer {
        interval: 30000
        repeat: true
        running: Notifications.centerOpen
        onTriggered: root.tick++
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: 0
        color: Theme.bg
        border.width: 1
        border.color: Theme.border

        opacity: Notifications.centerOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: Notifications.centerOpen ? 0 : -10
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Item {
            anchors.fill: parent
            focus: Notifications.centerOpen
            Keys.onEscapePressed: Notifications.centerOpen = false
        }

        // ── Header ───────────────────────────────────────────────────
        ColumnLayout {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: dndRow.implicitHeight + 20
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    id: dndRow
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: Notifications.dnd ? Icons.bellOff : Icons.bell
                        color: Notifications.dnd ? Theme.accent : Theme.subtext
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Do not disturb"
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            font.bold: true
                        }
                        Text {
                            text: Notifications.dnd ? "Alerts are paused" : "Allow pop-up alerts"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 12
                        }
                    }

                    Switch { checked: Notifications.dnd; onToggled: Notifications.toggle() }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 26
                        color: Theme.border
                    }

                    TextButton {
                        text: "Clear all"
                        sharp: true
                        enabled: Notifications.count > 0
                        onClicked: Notifications.clearAll()
                    }
                }
            }
        }

        // ── List ──────────────────────────────────────────────────────
        Flickable {
            id: flick
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.bottomMargin: 18
            anchors.topMargin: 0
            contentHeight: content.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: content
                width: flick.width
                spacing: 12

                Text {
                    visible: Notifications.count === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 44
                    Layout.bottomMargin: 44
                    horizontalAlignment: Text.AlignHCenter
                    text: "You’re all caught up"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }

                Repeater {
                    model: Notifications.groups

                    ColumnLayout {
                        id: group
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            Layout.leftMargin: 2
                            Layout.rightMargin: 2
                            Layout.bottomMargin: 2

                            Text {
                                Layout.fillWidth: true
                                text: group.modelData.app
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                font.bold: true
                            }
                            Text {
                                text: String(group.modelData.items.length)
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 11
                                Layout.rightMargin: 4
                            }
                            TextButton {
                                text: "Clear"
                                sharp: true
                                onClicked: group.modelData.items.slice().forEach(n => Notifications.dismiss(n))
                            }
                        }

                        Repeater {
                            model: group.modelData.items

                            NotifCard {
                                required property var modelData
                                Layout.fillWidth: true
                                compact: true
                                notif: modelData
                                refreshTick: root.tick
                            }
                        }
                    }
                }
            }
        }

        // Indikator scroll
        Rectangle {
            visible: flick.contentHeight > flick.height
            anchors.right: parent.right
            anchors.rightMargin: 3
            width: 3
            radius: 0
            color: Theme.surface2
            height: Math.max(24, flick.height * flick.height / Math.max(1, flick.contentHeight))
            y: flick.y + flick.contentY / Math.max(1, flick.contentHeight - flick.height) * (flick.height - height)
        }
    }
}
