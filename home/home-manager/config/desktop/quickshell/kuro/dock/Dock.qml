// Bottom dock: pinned apps and every open window in the center.
// Its enabled/autohide/disabled mode is managed by DockState.
//
//   left click    launch a pinned app, focus a window, or cycle app windows
//   middle click  close the app's window(s)
//   right click   app context menu: open, app actions, windows, pin/unpin
//   hover         window previews for every window of the grouped app
//
// Toggle the dock from Style -> Appearance -> Show dock or:
//   qs -c shell ipc call dock toggle

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.config
import qs.dock
import qs.services

Scope {
    id: root

    readonly property var toplevels: ToplevelManager.toplevels.values

    // Right-click menu state, shared by all monitors (only one is shown).
    property bool menuOpen: false
    property int menuIndex: -1
    property string menuKey: ""
    property string menuAppId: ""
    property var menuEntry: null
    property var menuWindows: []
    property string menuScreenName: ""
    property real menuAnchorX: 0
    property bool menuPinned: false

    // Hover preview state (one per screen, driven by the hovered dock item).
    property var previewItem: null
    property bool previewOpen: false
    property string previewScreen: ""
    property real previewAnchorX: 0
    property var pendingItem: null
    property real pendingX: 0
    property string pendingScreen: ""

    Timer { id: previewOpenTimer; interval: 170; onTriggered: root.commitPreview() }
    Timer { id: previewCloseTimer; interval: 240; onTriggered: root.closePreview() }

    function schedulePreview(item, x, screen) {
        if (root.menuOpen) return;
        previewCloseTimer.stop();
        root.pendingItem = item;
        root.pendingX = x;
        root.pendingScreen = screen;
        if (root.previewOpen && root.previewItem?.key === item.key) return;
        previewOpenTimer.restart();
    }

    function commitPreview() {
        if (!root.pendingItem || root.pendingItem.windows.length === 0) {
            root.closePreview();
            return;
        }
        previewCloseTimer.stop();
        root.previewItem = root.pendingItem;
        root.previewAnchorX = root.pendingX;
        root.previewScreen = root.pendingScreen;
        root.previewOpen = true;
    }

    function holdPreview() { previewCloseTimer.stop(); }
    function schedulePreviewClose() { previewCloseTimer.restart(); }

    function closePreview() {
        previewOpenTimer.stop();
        previewCloseTimer.stop();
        root.previewOpen = false;
        root.previewItem = null;
    }

    // ── App / window lookup ──────────────────────────────────────────
    function normalizedAppId(t) { return String(t.appId ?? "").toLowerCase() }

    function entryFor(appId) {
        if (!appId) return null;
        let e = DesktopEntries.heuristicLookup ? DesktopEntries.heuristicLookup(appId) : null;
        if (!e) e = DesktopEntries.byId(appId);
        if (!e) e = DesktopEntries.byId(appId + ".desktop");
        return e ?? null;
    }

    function iconFor(appId, entry) {
        const name = entry?.icon ?? appId;
        return name ? Quickshell.iconPath(name, true) : "";
    }

    function appName(appId, entry) { return entry?.name ?? appId; }

    function windowsFor(screenName, primary) {
        return root.toplevels.filter(t => {
            if (t.parent) return false;
            const screens = t.screens ?? [];
            if (screens.length === 0) return primary;
            return screens.some(s => s.name === screenName);
        });
    }

    // One entry per app: pinned apps first, in pin order, then running apps.
    function itemsFor(screenName, primary) {
        const out = [];
        const byKey = ({});
        const byAppId = ({});

        function ensure(key, appId, entry, pinned) {
            if (byKey[key]) {
                if (pinned) byKey[key].pinned = true;
                return byKey[key];
            }
            const item = { key: key, appId: appId, entry: entry, pinned: pinned, windows: [] };
            byKey[key] = item;
            byAppId[appId] = item;
            out.push(item);
            return item;
        }

        for (const id of DockState.pinned) {
            const entry = DesktopEntries.byId(id) ?? root.entryFor(id);
            const key = entry?.id ?? id;
            const appId = entry ? entry.id.replace(/\.desktop$/, "") : id;
            ensure(key, appId, entry, true);
        }

        for (const t of root.windowsFor(screenName, primary)) {
            const appId = root.normalizedAppId(t);
            const entry = root.entryFor(appId);
            const key = entry?.id ?? appId;
            let item = byKey[key] ?? byAppId[appId];
            if (!item) item = ensure(key, appId, entry, false);
            item.windows.push(t);
        }
        return out;
    }

    // ── Actions ──────────────────────────────────────────────────────
    function clickItem(item, button) {
        if (button === Qt.MiddleButton) {
            for (const t of item.windows.slice()) t.close();
            return;
        }
        if (item.windows.length === 0) {
            item.entry?.execute();
            return;
        }
        if (item.windows.length === 1) {
            item.windows[0].activate();
            return;
        }
        const active = item.windows.findIndex(t => t.activated);
        item.windows[(active + 1) % item.windows.length].activate();
    }

    function openMenu(item, x, screenName) {
        root.closePreview();
        root.menuKey = item.key;
        root.menuAppId = item.appId;
        root.menuEntry = item.entry;
        root.menuWindows = item.windows.slice();
        root.menuPinned = DockState.isPinned(item.key);
        root.menuAnchorX = x;
        root.menuScreenName = screenName;
        root.menuOpen = true;
        root.menuIndex = root.firstMenuIndex();
    }

    function closeMenu() {
        root.menuOpen = false;
        root.menuIndex = -1;
    }

    function togglePin() {
        DockState.togglePin(root.menuKey);
        root.menuPinned = DockState.isPinned(root.menuKey);
    }

    // Header, app actions, windows, pin, close. Each runnable item carries
    // `run`; headers and separators are skipped by the keyboard.
    function buildMenu() {
        const out = [];
        const entry = root.menuEntry;
        const name = root.appName(root.menuAppId, entry);

        out.push({ header: true, label: name });

        if (entry) {
            out.push({ label: "Open", glyph: Icons.g(0xF0416),
                       run: () => entry.execute() });
        }

        const actions = entry?.actions ?? [];
        for (let i = 0; i < Math.min(actions.length, 4); i++) {
            const a = actions[i];
            out.push({ label: a.name,
                       icon: a.icon ? Quickshell.iconPath(a.icon, true) : "",
                       glyph: Icons.g(0xF05B0),
                       run: () => a.execute() });
        }

        out.push({ sep: true });

        const wins = root.menuWindows;
        if (wins.length === 1) {
            out.push({ label: "Close " + (wins[0].title || "window"), glyph: Icons.close, danger: true,
                       run: () => wins[0].close() });
        } else if (wins.length > 1) {
            for (let i = 0; i < Math.min(wins.length, 8); i++) {
                const t = wins[i];
                out.push({ label: t.title || t.appId, glyph: Icons.g(0xF05B0), active: t.activated,
                           window: true, run: () => t.activate() });
            }
            out.push({ label: "Close all windows", glyph: Icons.close, danger: true,
                       run: () => { for (const t of wins.slice()) t.close(); } });
        }

        out.push({ label: root.menuPinned ? "Unpin from dock" : "Pin to dock",
                   glyph: Icons.g(root.menuPinned ? 0xF0404 : 0xF0403),
                   run: () => root.togglePin() });

        return out;
    }

    function firstMenuIndex() {
        const m = root.buildMenu();
        for (let i = 0; i < m.length; i++)
            if (!m[i].header && !m[i].sep) return i;
        return -1;
    }

    function moveMenu(d) {
        const m = root.buildMenu();
        if (m.length === 0) return;
        let i = root.menuIndex;
        for (let n = 0; n < m.length; n++) {
            i = (i + d + m.length) % m.length;
            if (!m[i].header && !m[i].sep) { root.menuIndex = i; return; }
        }
    }

    function activateMenu() {
        const item = root.buildMenu()[root.menuIndex];
        if (!item || item.header || item.sep) return;
        const fn = item.run;
        root.closeMenu();
        if (typeof fn === "function") fn();
    }

    Connections {
        target: DockState
        function onShownChanged() {
            if (DockState.shown) return;
            root.closeMenu();
            root.closePreview();
        }
    }

    // The dock itself, one per monitor.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            readonly property bool primary: modelData === Quickshell.screens[0]
            readonly property var items: root.itemsFor(modelData.name, primary)
            property bool hoverActive: false
            readonly property bool expanded: DockState.mode !== "autohide" || hoverActive
                || (root.menuOpen && root.menuScreenName === modelData.name)
                || (root.previewOpen && root.previewScreen === modelData.name)

            screen: modelData
            visible: DockState.shown
            anchors { bottom: true; left: true; right: true }
            implicitHeight: DockState.mode === "autohide" && !expanded ? 3 : Config.dockHeight
            color: "transparent"
            exclusionMode: DockState.mode === "enabled" ? ExclusionMode.Auto : ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell-dock"

            Timer {
                id: hideTimer
                interval: 500
                onTriggered: win.hoverActive = false
            }

            HoverHandler {
                id: dockHover
                onHoveredChanged: {
                    if (hovered) {
                        hideTimer.stop();
                        win.hoverActive = true;
                    } else if (DockState.mode === "autohide") {
                        hideTimer.restart();
                    }
                }
            }

            Connections {
                target: DockState
                function onModeChanged() {
                    if (DockState.mode === "autohide" && dockHover.hovered) win.hoverActive = true;
                    if (DockState.mode !== "autohide") hideTimer.stop();
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: win.expanded
                color: Theme.bg
            }

            // Top hairline, so the dock reads as a separate surface.
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                visible: win.expanded
                height: 1
                color: Theme.border
            }

            Flickable {
                id: flick
                anchors.fill: parent
                visible: win.expanded
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                clip: true
                contentWidth: Math.max(row.width, width)
                contentHeight: height
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                interactive: contentWidth > width

                Row {
                    id: row
                    x: Math.max(0, (flick.width - width) / 2)
                    y: (flick.height - height) / 2
                    spacing: 4

                    Repeater {
                        model: win.items

                        Rectangle {
                            id: item
                            required property var modelData
                            readonly property var app: modelData
                            readonly property bool hovered: mouse.containsMouse
                            readonly property bool running: app.windows.length > 0
                            readonly property bool active: app.windows.some(t => t.activated)

                            width: 40
                            height: 40
                            color: active
                                   ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                                   : hovered
                                     ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                                     : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Item {
                                anchors.centerIn: parent
                                width: 24
                                height: 24

                                IconImage {
                                    anchors.fill: parent
                                    source: root.iconFor(item.app.appId, item.app.entry)
                                    visible: source !== ""
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: root.iconFor(item.app.appId, item.app.entry) === ""
                                    text: Icons.g(0xF03D6)
                                    color: Theme.text
                                    font.family: Theme.iconFont
                                    font.pixelSize: 17
                                }
                            }

                            // Focused window marker (or a small running dot).
                            Rectangle {
                                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                                width: item.active ? 14 : item.running ? 4 : 0
                                height: 2
                                color: item.active ? Theme.accent : Theme.muted
                                Behavior on width { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.schedulePreview(item.app,
                                    item.mapToItem(win.contentItem, item.width / 2, 0).x,
                                    win.modelData.name)
                                onExited: root.schedulePreviewClose()
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton)
                                        root.openMenu(item.app,
                                            item.mapToItem(win.contentItem, item.width / 2, 0).x,
                                            win.modelData.name);
                                    else
                                        root.clickItem(item.app, mouse.button);
                                }
                            }
                        }
                    }
                }
            }

            // ── Hover previews: one card per grouped window ──────────
            PopupWindow {
                id: hoverPopup

                readonly property bool requestedOpen: DockState.shown && root.previewOpen
                    && root.previewItem !== null && root.previewScreen === win.modelData.name
                readonly property var preview: root.previewItem
                readonly property int count: preview ? preview.windows.length : 0
                readonly property int cols: Math.max(1, Math.min(3, count))
                readonly property int rows: Math.max(1, Math.ceil(count / cols))

                anchor.window: win
                anchor.rect.x: Math.max(8, Math.min(root.previewAnchorX - implicitWidth / 2,
                                                    win.width - implicitWidth - 8))
                anchor.rect.y: -implicitHeight - 8
                implicitWidth: cols * 150 + (cols - 1) * 6 + 16
                implicitHeight: 44 + rows * 108 + (rows - 1) * 6
                color: "transparent"
                visible: hoverPopup.requestedOpen || previewSurface.opacity > 0
                onVisibleChanged: if (visible && hoverPopup.requestedOpen) root.holdPreview()

                Rectangle {
                    id: previewSurface
                    anchors.fill: parent
                    color: Theme.bg
                    border.width: 1
                    border.color: Theme.border
                    clip: true
                    opacity: hoverPopup.requestedOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    transform: Translate {
                        y: hoverPopup.requestedOpen ? 0 : 8
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    HoverHandler {
                        id: previewHover
                        onHoveredChanged: hovered ? root.holdPreview() : root.schedulePreviewClose()
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 22

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: hoverPopup.preview
                                      ? root.appName(hoverPopup.preview.appId, hoverPopup.preview.entry)
                                      : ""
                                color: Theme.accent
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.letterSpacing: 1
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: hoverPopup.count + (hoverPopup.count === 1 ? " window" : " windows")
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 11
                            }
                        }

                        Flow {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: hoverPopup.preview
                                       ? hoverPopup.preview.windows.slice(0, 9)
                                       : []

                                Rectangle {
                                    id: card
                                    required property var modelData
                                    readonly property var entry: root.entryFor(String(modelData.appId ?? "").toLowerCase())

                                    width: 150
                                    height: 108
                                    color: Theme.surface
                                    border.width: 1
                                    border.color: modelData.activated ? Theme.accent : Theme.border
                                    clip: true

                                    ScreencopyView {
                                        id: shot
                                        anchors { top: parent.top; left: parent.left; right: parent.right
                                                  bottom: cardTitle.top }
                                        captureSource: card.modelData
                                        live: false
                                        visible: hasContent
                                    }

                                    Column {
                                        anchors { top: parent.top; left: parent.left; right: parent.right
                                                  bottom: cardTitle.top; margins: 6 }
                                        visible: !shot.visible
                                        spacing: 4

                                        IconImage {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            implicitSize: 26
                                            source: root.iconFor(String(card.modelData.appId ?? "").toLowerCase(),
                                                                 card.entry)
                                            visible: source !== ""
                                        }
                                        Text {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: card.modelData.title || card.modelData.appId || "Window"
                                            color: Theme.subtext
                                            font.family: Theme.font
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        id: cardTitle
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                        height: 26
                                        color: Theme.bg

                                        Text {
                                            anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                                            verticalAlignment: Text.AlignVCenter
                                            text: card.modelData.title || card.modelData.appId || "Window"
                                            color: modelData.activated ? Theme.accent : Theme.text
                                            font.family: Theme.font
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.closePreview();
                                            card.modelData.activate();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── App context menu ─────────────────────────────────────────────
    // A separate full-screen overlay, so the menu can sit above the dock
    // instead of being clipped by its 48px window.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: menuWin
            required property var modelData

            readonly property bool menuRequested: DockState.shown && root.menuOpen
                && root.menuScreenName === modelData.name

            screen: modelData
            visible: menuWin.menuRequested || menuBox.opacity > 0
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-dock-menu"
            WlrLayershell.keyboardFocus: menuWin.menuRequested ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onVisibleChanged: if (menuWin.menuRequested) menuBox.forceActiveFocus()

            HyprlandFocusGrab {
                windows: [menuWin]
                active: menuWin.menuRequested && menuWin.visible
                onCleared: root.closeMenu()
            }

            MouseArea {
                anchors.fill: parent
                enabled: menuWin.menuRequested
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: root.closeMenu()
            }

            Rectangle {
                id: menuBox
                readonly property var entries: root.buildMenu()

                x: Math.max(8, Math.min(root.menuAnchorX - width / 2, parent.width - width - 8))
                y: Math.max(8, parent.height - Config.dockHeight - 8 - height)
                width: 236
                height: menuCol.implicitHeight + 10
                color: Theme.bg
                border.width: 1
                border.color: Theme.border
                focus: true
                opacity: menuWin.menuRequested ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                transform: Translate {
                    y: menuWin.menuRequested ? 0 : 6
                    Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) root.closeMenu();
                    else if (event.key === Qt.Key_Down) root.moveMenu(1);
                    else if (event.key === Qt.Key_Up) root.moveMenu(-1);
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.activateMenu();
                    else return;
                    event.accepted = true;
                }

                MouseArea { anchors.fill: parent }

                Column {
                    id: menuCol
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 5 }
                    spacing: 0

                    Repeater {
                        model: menuBox.entries

                        Rectangle {
                            id: menuRow
                            required property var modelData
                            required property int index

                            width: menuCol.width
                            height: menuRow.modelData.sep ? 9 : menuRow.modelData.header ? 26 : 30
                            color: !menuRow.modelData.header && !menuRow.modelData.sep && root.menuIndex === menuRow.index
                                   ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                                   : menuRow.mouse.containsMouse && !menuRow.modelData.header && !menuRow.modelData.sep
                                     ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                                     : "transparent"
                            Behavior on color { ColorAnimation { duration: 90 } }

                            // Separator
                            Rectangle {
                                visible: menuRow.modelData.sep === true
                                anchors.centerIn: parent
                                width: parent.width
                                height: 1
                                color: Theme.border
                            }

                            // Header: app name
                            Text {
                                visible: menuRow.modelData.header === true
                                anchors { left: parent.left; right: parent.right; leftMargin: 8; rightMargin: 8
                                          verticalCenter: parent.verticalCenter }
                                text: menuRow.modelData.label ?? ""
                                color: Theme.accent
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.letterSpacing: 1
                                elide: Text.ElideRight
                            }

                            Row {
                                visible: !menuRow.modelData.header && !menuRow.modelData.sep
                                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                spacing: 8

                                Item {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16
                                    height: 16

                                    IconImage {
                                        anchors.fill: parent
                                        source: menuRow.modelData.icon ?? ""
                                        visible: source !== ""
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: (menuRow.modelData.icon ?? "") === ""
                                        text: menuRow.modelData.glyph ?? Icons.g(0xF05B0)
                                        color: Theme.text
                                        font.family: Theme.iconFont
                                        font.pixelSize: 14
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 24
                                    text: menuRow.modelData.label ?? ""
                                    color: menuRow.modelData.danger ? Theme.danger
                                           : menuRow.modelData.active ? Theme.accent : Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: menuRowMouse
                                anchors.fill: parent
                                enabled: !menuRow.modelData.header && !menuRow.modelData.sep
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.menuIndex = menuRow.index
                                onClicked: root.activateMenu()
                            }

                            // Alias used by color binding above.
                            property alias mouse: menuRowMouse
                        }
                    }
                }
            }
        }
    }
}
