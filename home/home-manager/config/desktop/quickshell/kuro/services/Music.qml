pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// MPD library, playback, and queue state for the Kuro player.
Singleton {
    id: root

    property bool active: false
    property var library: []
    property var queue: []
    property var playlists: []
    property var importedFolders: []
    property string folderStatus: ""
    property string page: "library"
    property string search: ""
    property string state: "stopped"
    property string currentArtist: ""
    property string currentTitle: ""
    property string currentAlbum: ""
    property string currentFile: ""
    property int elapsed: 0
    property int duration: 0
    property int volume: 50
    property bool random: false
    property bool repeat: false
    property bool single: false
    property bool consume: false
    property bool autoScanOnOpen: true
    property bool settingsLoaded: false
    readonly property string musicDirectory: Config.home + "/Music"
    property string error: ""
    property string databaseState: ""
    property var activeCommand: []
    property int revision: 0
    signal toggleRequested()
    signal openRequested()
    property var commandQueue: []

    readonly property var filteredLibrary: {
        const q = search.trim().toLowerCase();
        if (q === "") return library;
        return library.filter(track => [track.title, track.artist, track.album, track.file]
            .some(value => String(value ?? "").toLowerCase().includes(q)));
    }

    function parseTracks(raw) {
        return raw.split("\n").filter(line => line.trim() !== "").map((line, index) => {
            const parts = line.split("\t");
            const file = parts[3] ?? parts[0] ?? "";
            const title = (parts[1] ?? "").trim() || file.split("/").pop().replace(/\.[^.]+$/, "");
            return { artist: (parts[0] ?? "").trim(), title, album: (parts[2] ?? "").trim(), file, duration: root.parseTime(parts[4] ?? 0), index };
        });
    }

    function parseTime(value) {
        const parts = String(value ?? "0").split(":").map(Number);
        if (parts.some(n => !Number.isFinite(n))) return 0;
        return parts.length === 3 ? parts[0] * 3600 + parts[1] * 60 + parts[2]
            : parts.length === 2 ? parts[0] * 60 + parts[1] : (parts[0] || 0);
    }

    function formatTime(value) {
        const seconds = Math.max(0, Math.floor(Number(value) || 0));
        const h = Math.floor(seconds / 3600), m = Math.floor((seconds % 3600) / 60), s = seconds % 60;
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
            : m + ":" + String(s).padStart(2, "0");
    }

    function toggleWindow() { toggleRequested(); }
    function openWindow() { openRequested(); }

    function saveSettings() {
        if (!settingsLoaded) return;
        settingsProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
            "sh", JSON.stringify({ autoScanOnOpen: autoScanOnOpen }),
            Config.home + "/.config/kuro/music.json"];
        settingsProc.running = true;
    }

    function setAutoScan(value) { autoScanOnOpen = value; saveSettings(); }
    function openMusicFolder() {
        folderProc.command = ["xdg-open", musicDirectory];
        folderProc.running = true;
    }
    function refreshMusicFolders() {
        if (!foldersProc.running) foldersProc.running = true;
    }
    function addMusicFolder(path) {
        folderStatus = "Adding folder to the MPD library…";
        folderActionProc.command = [Config.home + "/.config/quickshell/shell/bin/music-folders", "add", path];
        folderActionProc.running = true;
    }
    function removeMusicFolder(name) {
        folderStatus = "Removing imported folder…";
        folderActionProc.command = [Config.home + "/.config/quickshell/shell/bin/music-folders", "remove", name];
        folderActionProc.running = true;
    }

    function refresh() {
        if (!libraryProc.running) libraryProc.running = true;
        if (!queueProc.running) queueProc.running = true;
        if (!statusProc.running) statusProc.running = true;
        if (!currentProc.running) currentProc.running = true;
        if (!playlistsProc.running) playlistsProc.running = true;
    }

    function execute(commands) {
        commandQueue = commandQueue.concat(commands);
        runNext();
    }

    function runNext() {
        if (commandProc.running || commandQueue.length === 0) return;
        const args = commandQueue[0];
        commandQueue = commandQueue.slice(1);
        activeCommand = args;
        commandProc.command = ["mpc"].concat(args);
        commandProc.running = true;
    }

    function playTrack(track) {
        if (!track || !track.file) return;
        execute([["clear"], ["add", track.file], ["play"]]);
    }
    function enqueueTrack(track) { if (track?.file) execute([["add", track.file]]); }
    function playQueue(index) { execute([["play", String(index + 1)]]); }
    function removeQueue(index) { execute([["del", String(index + 1)]]); }
    function togglePlayback() { execute([[state === "playing" ? "pause" : "play"]]); }
    function next() { execute([["next"]]); }
    function previous() { execute(elapsed > 3 ? [["seek", "0"]] : [["prev"]]); }
    function seekTo(seconds) { execute([["seek", String(Math.max(0, Math.floor(seconds)))] ]); }
    function setVolume(value) { execute([["volume", String(Math.max(0, Math.min(100, Math.round(value))))]]); }
    function toggleRandom() { execute([["random", random ? "off" : "on"]]); }
    function toggleRepeat() { execute([["repeat", repeat ? "off" : "on"]]); }
    function toggleSingle() { execute([["single", single ? "off" : "on"]]); }
    function toggleConsume() { execute([["consume", consume ? "off" : "on"]]); }
    function stop() { execute([["stop"]]); }
    function clearQueue() { execute([["clear"]]); }
    function playPlaylist(name) { execute([["clear"], ["load", name], ["play"]]); }
    function savePlaylist(name) {
        const safeName = String(name ?? "").trim();
        if (safeName !== "") execute([["save", safeName]]);
    }
    function deletePlaylist(name) {
        const safeName = String(name ?? "").trim();
        if (safeName !== "") execute([["rm", safeName]]);
    }
    function updateDatabase() { databaseState = "Scanning music folder…"; execute([["update", "--wait"]]); }

    Process {
        id: libraryProc
        command: ["mpc", "--format", "%artist%\t%title%\t%album%\t%file%\t%time%", "listall"]
        stdout: StdioCollector { onStreamFinished: root.library = root.parseTracks(text); }
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") root.error = text.trim(); }
        onExited: exitCode => { if (exitCode !== 0 && root.library.length === 0) root.error = root.error || "Could not read MPD library."; }
    }

    Process {
        id: queueProc
        command: ["mpc", "--format", "%artist%\t%title%\t%album%\t%file%\t%time%", "playlist"]
        stdout: StdioCollector { onStreamFinished: root.queue = root.parseTracks(text); }
    }

    Process {
        id: currentProc
        command: ["mpc", "--format", "%artist%\t%title%\t%album%\t%file%\t%time%", "current"]
        stdout: StdioCollector {
            onStreamFinished: {
                const track = root.parseTracks(text)[0] ?? {};
                root.currentArtist = track.artist ?? "";
                root.currentTitle = track.title ?? "";
                root.currentAlbum = track.album ?? "";
                root.currentFile = track.file ?? "";
                if (track.duration > 0) root.duration = track.duration;
                root.revision++;
            }
        }
    }

    Process {
        id: statusProc
        command: ["mpc", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text;
                if (value.trim() === "") root.error = "MPD is unavailable. Check the MPD user service.";
                else root.error = "";
                root.state = value.includes("[playing]") ? "playing" : value.includes("[paused]") ? "paused" : "stopped";
                const vm = value.match(/volume:\s*(\d+)%/i);
                if (vm) root.volume = Number(vm[1]);
                const progress = value.match(/(?:\[playing\]|\[paused\])\s+#[^\s]+\s+(\d+:\d+(?::\d+)?)\/(\d+:\d+(?::\d+)?)/);
                if (progress) { root.elapsed = root.parseTime(progress[1]); root.duration = root.parseTime(progress[2]); }
                root.random = /random:\s*on/i.test(value);
                root.repeat = /repeat:\s*on/i.test(value);
                root.single = /single:\s*on/i.test(value);
                root.consume = /consume:\s*on/i.test(value);
                if (/updating_db:/i.test(value) && root.databaseState !== "") root.databaseState = "Scanning music folder…";
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") root.error = text.trim(); }
    }

    Process {
        id: playlistsProc
        command: ["mpc", "lsplaylists"]
        stdout: StdioCollector { onStreamFinished: root.playlists = text.split("\n").map(x => x.trim()).filter(Boolean); }
    }

    Process {
        id: foldersProc
        command: [Config.home + "/.config/quickshell/shell/bin/music-folders", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.importedFolders = text.split("\n").filter(Boolean).map(line => {
                const tab = line.indexOf("\t");
                return { name: tab < 0 ? line : line.slice(0, tab), path: tab < 0 ? "" : line.slice(tab + 1) };
            });
        }
    }

    Process {
        id: folderActionProc
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") root.folderStatus = text.trim(); }
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") root.folderStatus = text.trim(); }
        onExited: exitCode => {
            if (exitCode === 0) {
                root.refreshMusicFolders();
                root.updateDatabase();
            }
        }
    }

    Process {
        id: commandProc
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") root.error = text.trim(); }
        onExited: exitCode => {
            if (exitCode !== 0) root.error = root.error || "MPD command failed.";
            if (root.activeCommand.length > 0 && root.activeCommand[0] === "update") {
                root.databaseState = "";
                root.refresh();
            }
            root.activeCommand = [];
            root.refresh();
            root.runNext();
        }
    }

    Process { id: settingsProc }
    Process { id: folderProc }

    FileView {
        path: Config.home + "/.config/kuro/music.json"
        printErrors: false
        onLoaded: {
            try {
                const settings = JSON.parse(text());
                root.autoScanOnOpen = settings.autoScanOnOpen !== false;
            } catch (e) { }
            root.settingsLoaded = true;
        }
        onLoadFailed: root.settingsLoaded = true
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: {
            if (!statusProc.running) statusProc.running = true;
            if (!currentProc.running) currentProc.running = true;
        }
    }

    Timer {
        interval: 1200
        repeat: true
        running: root.databaseState !== ""
        onTriggered: {
            if (!statusProc.running) statusProc.running = true;
            if (!libraryProc.running) libraryProc.running = true;
        }
    }

    Component.onCompleted: {
        refresh();
        refreshMusicFolders();
    }
}
