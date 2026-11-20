// Settings window: sidebar navigation + pages on the right.
// FloatingWindow = a regular app window (xdg-toplevel), not a layer-shell panel.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.pages

FloatingWindow {
    id: root

    title: "Control Center"     // used by the Hyprland windowrule
    visible: false

    implicitWidth: Theme.windowWidth
    implicitHeight: Theme.windowHeight
    color: Theme.bg

    property int page: 0
    function toggle() { visible = !visible; }

    // Order here = order of the StackLayout below. `keywords` are used for search.
    readonly property var pages: [
        { label: "Profile",    section: "overview", num: "01", keywords: "system cpu memory temp telemetry quick" },
        { label: "Network",    section: "devices",  num: "02", keywords: "wifi wi-fi ethernet lan internet ip cable" },
        { label: "Bluetooth",  section: "devices",  num: "02", keywords: "headset earbuds pair device" },
        { label: "Sound",      section: "devices",  num: "02", keywords: "audio volume speaker mic microphone output input" },
        { label: "Display",    section: "devices",  num: "02", keywords: "brightness night light screen resolution hyprsunset" },
        { label: "Appearance", section: "look",     num: "03", keywords: "pywal theme colors gaps rounding blur animation bar waybar layout" },
        { label: "Wallpaper",  section: "look",     num: "03", keywords: "awww swww background image pywal" },
        { label: "Widgets",    section: "look",     num: "03", keywords: "desktop widget github contributions graph clock" },
        { label: "Clipboard",  section: "system",   num: "04", keywords: "cliphist copy paste history" },
        { label: "Notifications", section: "system", num: "04", keywords: "notification dnd do not disturb popup history swaync" },
        { label: "Power",      section: "system",   num: "04", keywords: "battery profile lock suspend logout reboot shutdown" },
        { label: "Keybinds",   section: "system",   num: "04", keywords: "shortcuts keys bind hotkey" }
    ]

    function isActive(i) { return root.visible && root.page === i; }

    // Open a specific page directly, e.g. "network" or "sound".
    // If that page is already open, the window closes (toggle behavior).
    function openPage(name) {
        const i = pages.findIndex(p => p.label.toLowerCase() === name.toLowerCase());
        if (i < 0) { visible = true; return; }
        if (visible && page === i) { visible = false; return; }
        page = i;
        visible = true;
    }

    onVisibleChanged: if (visible) { fadeIn.restart(); body.forceActiveFocus(); }

    // If the window is closed from outside (e.g. killactive in Hyprland), sync the
    // `visible` state so the next toggle opens it instead of "closing" it first.
    Connections {
        target: root
        ignoreUnknownSignals: true
        function onClosed() { root.visible = false; }
    }

    Item {
        id: body
        anchors.fill: parent
        focus: true

        // Esc = clear search / close · Ctrl+1..9 = page · Ctrl+F = search
        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) {
                if (sidebar.query !== "") sidebar.query = "";
                else root.visible = false;
                event.accepted = true;
            } else if (ctrl && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                const i = event.key - Qt.Key_1;
                if (i < root.pages.length) root.page = i;
                event.accepted = true;
            } else if (ctrl && event.key === Qt.Key_F) {
                sidebar.focusSearch();
                event.accepted = true;
            }
        }

        NumberAnimation {
            id: fadeIn
            target: body; property: "opacity"
            from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Sidebar {
                id: sidebar
                Layout.fillHeight: true
                Layout.preferredWidth: Theme.sidebarWidth
                pages: root.pages
                current: root.page
                onSelected: i => { root.page = i; body.forceActiveFocus(); }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: Theme.border
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 28
                Layout.bottomMargin: 20
                Layout.leftMargin: 28
                Layout.rightMargin: 14
                currentIndex: root.page

                OverviewPage   { active: root.isActive(0) }
                NetworkPage    { active: root.isActive(1) }
                BluetoothPage  { active: root.isActive(2) }
                SoundPage      { active: root.isActive(3) }
                DisplayPage    { active: root.isActive(4) }
                AppearancePage { active: root.isActive(5) }
                WallpaperPage  { active: root.isActive(6); onCloseRequested: root.visible = false }
                WidgetsPage    { active: root.isActive(7) }
                ClipboardPage  { active: root.isActive(8) }
                NotificationsPage { active: root.isActive(9) }
                PowerPage      { active: root.isActive(10); onActionTriggered: root.visible = false }
                KeybindsPage   { active: root.isActive(11) }
            }
        }
    }
}
