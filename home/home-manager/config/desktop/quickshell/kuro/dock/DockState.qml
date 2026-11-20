pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Dock mode and pins are remembered across restarts.
Singleton {
    id: root

    property string mode: Config.dockEnabled ? "enabled" : "disabled"
    readonly property bool shown: mode !== "disabled"

    // Desktop entry ids (e.g. "kitty.desktop"), in dock order.
    property var pinned: []

    function toggle() { setMode(shown ? "disabled" : "enabled"); }
    function setVisible(v) { setMode(v ? "enabled" : "disabled"); }
    function setMode(value) {
        if (["enabled", "disabled", "autohide"].indexOf(value) < 0) return false;
        if (mode === value) return true;
        mode = value;
        save();
        return true;
    }

    function isPinned(id) { return !!id && pinned.indexOf(id) !== -1; }

    function pin(id) {
        if (!id || isPinned(id)) return;
        pinned = pinned.concat([id]);
        savePinned();
    }

    function unpin(id) {
        if (!isPinned(id)) return;
        pinned = pinned.filter(x => x !== id);
        savePinned();
    }

    function togglePin(id) { isPinned(id) ? unpin(id) : pin(id); }

    function save() {
        saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
                            "sh", mode, Config.dockStateFile];
        saveProc.running = true;
    }

    function savePinned() {
        pinnedProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
                              "sh", JSON.stringify(pinned), Config.dockPinnedFile];
        pinnedProc.running = true;
    }

    FileView {
        path: Config.dockStateFile
        printErrors: false
        onLoaded: {
            const v = text().trim();
            if (v === "on") root.mode = "enabled";
            else if (v === "off") root.mode = "disabled";
            else if (["enabled", "disabled", "autohide"].indexOf(v) >= 0) root.mode = v;
        }
    }

    FileView {
        path: Config.dockPinnedFile
        printErrors: false
        onLoaded: {
            try {
                const v = JSON.parse(text());
                if (Array.isArray(v)) root.pinned = v.filter(x => typeof x === "string");
            } catch (e) {}
        }
    }

    Process { id: saveProc }
    Process { id: pinnedProc }
}
