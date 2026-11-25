pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config

// Data for the workspace overview: windows & monitors from hyprctl, fetched when the overview opens.
Singleton {
    id: root

    property bool shown: false
    property var clients: []        // [{ address, ws, x, y, w, h, cls, title, floating, monitor }]
    property var monitors: ({})     // name -> { x, y, w, h, activeWs }
    property bool loaded: false
    property bool blurChangedForOverview: false
    property bool restoreBlurAfterEnable: false

    // Build reusable indexes when window/toplevel data changes instead of
    // filtering and scanning the complete lists from every preview delegate.
    readonly property var clientsByWorkspace: {
        const groups = Object.create(null);
        for (const client of clients) {
            const key = String(client.ws);
            if (!groups[key]) groups[key] = [];
            groups[key].push(client);
        }
        return groups;
    }
    readonly property var toplevelsByAddress: {
        const index = Object.create(null);
        for (const toplevel of (Hyprland.toplevels?.values ?? [])) {
            const address = normAddr(toplevel.address);
            if (address) index[address] = toplevel.wayland ?? null;
        }
        return index;
    }

    function toggle() { shown ? close() : open(); }
    function open() {
        if (shown) return;
        restoreBlurAfterEnable = false;
        refresh();
        shown = true;
        if (!blurReadProc.running && !blurEnableProc.running && !blurRestoreProc.running)
            blurReadProc.running = true;
    }

    function close() {
        shown = false;
        if (blurEnableProc.running) restoreBlurAfterEnable = true;
        else restoreBlur();
    }

    function restoreBlur() {
        if (!blurChangedForOverview) return;
        blurChangedForOverview = false;
        blurRestoreProc.running = true;
    }

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    // "0x55d1a2b3c4d5" and "55d1a2b3c4d5" are treated as the same
    function normAddr(a) { return String(a ?? "").toLowerCase().replace(/^0x/, ""); }

    function windowsOn(ws) { return clientsByWorkspace[String(ws)] ?? []; }

    function focusWindow(c) {
        Hyprland.dispatch("focuswindow address:0x" + normAddr(c.address));
        close();
    }

    function goTo(ws) {
        Hyprland.dispatch("workspace " + ws);
        close();
    }

    function moveWindow(c, ws) {
        if (!c || c.ws === ws || !Number.isInteger(Number(ws)) || Number(ws) < 1) return;
        // Use the normal dispatcher so dropping onto a workspace switches to it.
        Hyprland.dispatch("movetoworkspace " + Number(ws) + ",address:0x" + normAddr(c.address));
        close();
        refreshLater.restart();
    }

    function closeWindow(c) {
        Hyprland.dispatch("closewindow address:0x" + normAddr(c.address));
        clients = clients.filter(x => x.address !== c.address);
        refreshLater.restart();
    }

    // Wayland toplevel for the preview (ScreencopyView). null if not found.
    function toplevelFor(address) {
        return toplevelsByAddress[normAddr(address)] ?? null;
    }

    Timer { id: refreshLater; interval: 300; onTriggered: root.refresh() }

    Process {
        id: blurReadProc
        command: ["hyprctl", "-j", "getoption", "decoration:blur:enabled"]
        stdout: StdioCollector {
            onStreamFinished: {
                let enabled = true;
                try {
                    const option = JSON.parse(text);
                    enabled = option.bool !== undefined ? option.bool : option.int !== 0;
                } catch (e) { return; }

                if (!enabled && root.shown) {
                    root.blurChangedForOverview = true;
                    blurEnableProc.running = true;
                }
            }
        }
    }

    Process {
        id: blurEnableProc
        command: ["hyprctl", "keyword", "decoration:blur:enabled", "true"]
        onExited: if (root.restoreBlurAfterEnable || !root.shown) {
            root.restoreBlurAfterEnable = false;
            root.restoreBlur();
        }
    }

    Process {
        id: blurRestoreProc
        command: ["hyprctl", "keyword", "decoration:blur:enabled", "false"]
        onExited: if (root.shown && !blurReadProc.running && !blurEnableProc.running)
            blurReadProc.running = true
    }

    Process {
        id: proc
        command: ["sh", "-c", "hyprctl -j clients; echo '\n@@SPLIT@@'; hyprctl -j monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("@@SPLIT@@");
                let cl = [], mo = [];
                try { cl = JSON.parse(parts[0]); mo = JSON.parse(parts[1]); } catch (e) { return; }

                const mons = {};
                for (const m of mo) {
                    // logical size (after scale & rotation)
                    const rot = (m.transform ?? 0) % 2 === 1;
                    const pw = rot ? m.height : m.width, ph = rot ? m.width : m.height;
                    mons[m.name] = {
                        x: m.x, y: m.y,
                        w: pw / (m.scale || 1), h: ph / (m.scale || 1),
                        activeWs: m.activeWorkspace?.id ?? -1
                    };
                }

                const idToMon = {};
                for (const m of mo) idToMon[m.id] = m.name;

                root.monitors = mons;
                root.clients = cl
                    .filter(c => c.mapped !== false && (c.workspace?.id ?? -1) > 0)
                    .map(c => ({
                        address: c.address,
                        ws: c.workspace.id,
                        x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1],
                        cls: c.class || c.initialClass || "",
                        title: c.title || "",
                        floating: c.floating === true,
                        monitor: idToMon[c.monitor] ?? ""
                    }));
                root.loaded = true;
            }
        }
    }

    // Data is also refreshed when Hyprland sends events while the overview is open
    Connections {
        target: Hyprland
        enabled: root.shown
        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindow", "movewindowv2", "workspace", "focusedmon"]
                    .includes(event.name))
                refreshLater.restart();
        }
    }
}
