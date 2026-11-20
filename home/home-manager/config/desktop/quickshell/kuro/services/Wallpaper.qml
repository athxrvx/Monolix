pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Wallpaper: only displays images and CALLS your script.
//   set(path)    -> Config.wallpaperSet   (backend: awww + pywal + etc.)
//   openPicker() -> Config.wallpaperPicker (your frontend, optional)
// Control Center colors change too because Theme.qml watches pywal's colors.json.
Singleton {
    id: root

    property string current: ""       // read from the awww daemon
    property var images: []
    property string applying: ""
    property bool loading: false
    property string error: ""

    readonly property bool hasPicker: Config.wallpaperPicker !== ""

    function refresh() {
        if (listProc.running) return;
        loading = true;
        listProc.running = true;
    }

    function set(path) {
        if (setProc.running) return;
        error = "";
        applying = path;
        // stdout/stderr to a log file, stdin from /dev/null: background processes started
        // by the backend (waybar, spicetify) don't hold Quickshell's pipes.
        setProc.command = ["sh", "-c",
            Config.wallpaperSet + ' </dev/null >"$2" 2>&1', "sh", path, Config.wallpaperLog];
        setProc.running = true;
    }

    function openPicker() {
        if (hasPicker) Quickshell.execDetached(["sh", "-c", Config.wallpaperPicker]);
    }

    function fileName(path) { return path.split("/").pop(); }

    readonly property string script: [
        'echo "$(awww query 2>/dev/null | grep -m1 -oE "image: .*" | sed "s/^image: //")"',
        'find -L "$1" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \\) 2>/dev/null | sort'
    ].join("\n")

    Process {
        id: listProc
        command: ["sh", "-c", root.script, "sh", Config.wallpaperDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                root.current = l[0] ?? "";
                root.images = l.slice(1).filter(p => p !== "");
                root.loading = false;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.error = text.trim().split("\n").pop()
        }
        // Safety net: if stdout never finishes, don't get stuck "loading"
        onExited: (code, status) => {
            if (code !== 0 && root.error === "") root.error = "Failed to read folder (code " + code + ")";
            listTimeout.restart();
        }
    }

    Timer {
        id: listTimeout
        interval: 1500
        onTriggered: if (root.loading) {
            root.loading = false;
            if (root.error === "") root.error = "Process finished but output was unreadable.";
        }
    }

    Process {
        id: setProc
        onExited: (code, status) => {
            if (code === 0) root.current = root.applying;
            else root.error = "wallset-backend failed (code " + code + "). See " +
                              Config.wallpaperLog.replace(Config.home, "~");
            root.applying = "";
        }
    }
}
