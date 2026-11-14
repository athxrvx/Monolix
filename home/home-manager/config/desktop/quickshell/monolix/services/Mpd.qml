pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string title: ""
    property string artist: ""
    property string album: ""
    property string statusText: qsTr("MPD is starting…")
    property bool playing: false
    property bool random: false
    property bool repeat: false
    property int elapsed: 0
    property int duration: 0
    property int volume: -1
    property int currentPosition: 0
    property list<var> queue: []
    property list<var> library: []
    property bool available: false
    property string _currentOutput: ""
    property string _statusOutput: ""
    property bool _refreshLibraryAfterAction: false
    property bool _playAfterAdd: false
    property int _playPositionAfterAdd: 1

    function refresh(): void {
        if (!currentProcess.running)
            currentProcess.running = true;
        if (!statusProcess.running)
            statusProcess.running = true;
        if (!queueProcess.running)
            queueProcess.running = true;
    }

    function refreshLibrary(): void {
        if (!libraryProcess.running)
            libraryProcess.running = true;
    }

    function run(action: string): void {
        _refreshLibraryAfterAction = action === "update";
        actionProcess.command = ["mpc", ...action.split(" ").filter(part => part.length > 0)];
        actionProcess.running = true;
    }

    function addTrack(path: string): void {
        actionProcess.command = ["mpc", "add", path];
        actionProcess.running = true;
    }

    function playLibraryTrack(path: string): void {
        _playPositionAfterAdd = Math.max(1, queue.length + 1);
        _playAfterAdd = true;
        actionProcess.command = ["mpc", "add", path];
        actionProcess.running = true;
    }

    function playTrack(position: int): void {
        actionProcess.command = ["mpc", "play", position.toString()];
        actionProcess.running = true;
    }

    function seekTo(seconds: real): void {
        actionProcess.command = ["mpc", "seek", Math.floor(seconds).toString()];
        actionProcess.running = true;
    }

    function adjustVolume(delta: int): void {
        actionProcess.command = ["mpc", "volume", `${delta >= 0 ? "+" : ""}${delta}`];
        actionProcess.running = true;
    }

    function parseCurrent(output: string): void {
        const lines = output.trim().split("\n");
        const titleAndFile = (lines[0] || "").split("|");
        const fileName = titleAndFile[1] ? titleAndFile[1].split("/").pop().replace(/\.[^.]+$/, "") : "";
        title = titleAndFile[0] || fileName;
        artist = lines[1] || "";
        album = lines[2] || "";
    }

    function parseStatus(output: string, exitCode: int): void {
        available = exitCode === 0;
        if (!available) {
            playing = false;
            statusText = qsTr("MPD is unavailable. Start the music service or add files to ~/Music.");
            return;
        }

        const lines = output.split("\n");
        const playback = lines.find(line => /\[(playing|paused|stopped)\]/.test(line)) || "";
        playing = playback.includes("[playing]");
        statusText = playback.includes("[playing]") ? qsTr("Playing")
            : playback.includes("[paused]") ? qsTr("Paused")
            : qsTr("Library ready");
        const time = playback.match(/(\d+):(\d+)\/(\d+):(\d+)/);
        elapsed = time ? Number(time[1]) * 60 + Number(time[2]) : 0;
        duration = time ? Number(time[3]) * 60 + Number(time[4]) : 0;
        const positionMatch = playback.match(/#(\d+)\//);
        currentPosition = positionMatch ? Number(positionMatch[1]) : 0;
        const vol = output.match(/volume:\s*(\d+)%/);
        volume = vol ? Number(vol[1]) : -1;
        random = /random:\s*on/i.test(output);
        repeat = /repeat:\s*on/i.test(output);
    }

    function parseQueue(output: string): void {
        const parsed = [];
        for (const line of output.trim().split("\n")) {
            const parts = line.split("|");
            if (parts.length < 3)
                continue;
            parsed.push({ position: Number(parts[0]), title: parts[1], artist: parts.slice(2).join("|") });
        }
        queue = parsed;
    }

    function parseLibrary(output: string): void {
        const parsed = [];
        for (const line of output.trim().split("\n")) {
            const parts = line.split("|");
            if (!parts[0])
                continue;
            const fileName = parts[0].split("/").pop().replace(/\.[^.]+$/, "");
            parsed.push({ path: parts[0], title: parts[1] || fileName, artist: parts.slice(2).join("|") });
        }
        library = parsed;
    }

    Process {
        id: currentProcess
        command: ["mpc", "--format", "%title%|%file%\\n%artist%\\n%album%", "current"]
        running: false
        stdout: StdioCollector { onStreamFinished: root._currentOutput = text }
        onExited: (code) => root.parseCurrent(root._currentOutput)
    }

    Process {
        id: statusProcess
        command: ["mpc", "status"]
        running: false
        stdout: StdioCollector { onStreamFinished: root._statusOutput = text }
        onExited: (code) => root.parseStatus(root._statusOutput, code)
    }

    Process {
        id: queueProcess
        command: ["mpc", "--format", "%position%|%title%|%artist%", "playlist"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.parseQueue(text) }
    }

    Process {
        id: libraryProcess
        command: ["mpc", "--format", "%file%|%title%|%artist%", "listall"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.parseLibrary(text) }
    }

    Process {
        id: actionProcess
        running: false
        onExited: {
            if (root._playAfterAdd) {
                root._playAfterAdd = false;
                actionProcess.command = ["mpc", "play", root._playPositionAfterAdd.toString()];
                actionProcess.running = true;
                return;
            }
            root.refresh();
            if (root._refreshLibraryAfterAction)
                root.refreshLibrary();
            root._refreshLibraryAfterAction = false;
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        refresh();
        // Refresh MPD's database so newly copied files in ~/Music appear
        // without requiring users to know that MPD keeps its own index.
        run("update");
    }
}
