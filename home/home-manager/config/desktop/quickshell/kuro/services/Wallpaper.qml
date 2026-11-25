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
    property bool refreshPending: false
    property bool thumbnailLoading: false
    property bool thumbnailRefreshPending: false
    property string error: ""
    property var thumbnails: ({})
    property var imageSignatures: ({})
    property double lastRefresh: 0

    readonly property bool hasPicker: Config.wallpaperPicker !== ""

    function refresh(force = false) {
        if (listProc.running) {
            if (force) root.refreshPending = true;
            return;
        }
        if (!force && Date.now() - lastRefresh < 60000) return;
        loading = true;
        listProc.running = true;
    }

    function thumbnail(path) {
        return thumbnails[path] ?? (thumbnailLoading ? "" : path);
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

    Process {
        id: listProc
        command: [Config.wallpaperIndexScript, Config.wallpaperDir]
        stdout: StdioCollector {
            onStreamFinished: {
                let snapshot;
                try { snapshot = JSON.parse(text); }
                catch (e) {
                    root.error = "Could not read wallpaper index: " + e;
                    root.loading = false;
                    return;
                }

                root.current = snapshot.current ?? "";
                root.error = "";
                const nextImages = [];
                const nextSignatures = {};
                const changedImages = [];
                for (const item of (snapshot.items ?? [])) {
                    const path = item.path;
                    const signature = item.signature;
                    nextImages.push(path);
                    nextSignatures[path] = signature;
                    if (root.imageSignatures[path] !== signature || root.thumbnails[path] === undefined)
                        changedImages.push(path);
                }

                const imagesChanged = nextImages.length !== root.images.length
                    || nextImages.some((path, index) => path !== root.images[index]);
                if (imagesChanged) root.images = nextImages;
                root.imageSignatures = nextSignatures;
                root.lastRefresh = Date.now();
                root.loading = false;
                const retained = {};
                for (const path in root.thumbnails) {
                    if (nextSignatures[path] !== undefined) retained[path] = root.thumbnails[path];
                }
                root.thumbnails = retained;
                if (changedImages.length > 0) {
                    root.thumbnailLoading = true;
                    if (thumbProc.running) root.thumbnailRefreshPending = true;
                    else thumbProc.running = true;
                } else if (!thumbProc.running) {
                    root.thumbnailLoading = false;
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.error = text.trim().split("\n").pop()
        }
        // Safety net: if stdout never finishes, don't get stuck "loading"
        onExited: (code, status) => {
            if (code !== 0 && root.error === "") root.error = "Failed to read folder (code " + code + ")";
            listTimeout.restart();
            if (root.refreshPending) {
                root.refreshPending = false;
                root.refresh(true);
            }
        }
    }

    Process {
        id: thumbProc
        command: ["nice", "-n", "10", Config.wallpaperThumbScript, Config.wallpaperThumbCache, Config.wallpaperDir]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const split = line.indexOf("\t");
                if (split <= 0) return;
                const map = Object.assign({}, root.thumbnails);
                map[line.slice(0, split)] = line.slice(split + 1);
                root.thumbnails = map;
            }
        }
        onExited: (code, status) => {
            if (code === 0 && root.thumbnailRefreshPending && root.images.length > 0) {
                root.thumbnailRefreshPending = false;
                thumbProc.running = true;
                return;
            }
            root.thumbnailLoading = false;
            root.thumbnailRefreshPending = false;
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
