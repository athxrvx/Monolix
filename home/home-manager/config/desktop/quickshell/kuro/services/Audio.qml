pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Audio via wpctl (PipeWire/WirePlumber): volume & mute for speaker and mic,
// list of outputs/inputs, select the default device.
Singleton {
    id: root

    readonly property string sink: "@DEFAULT_AUDIO_SINK@"
    readonly property string source: "@DEFAULT_AUDIO_SOURCE@"

    property real volume: 0
    property bool muted: false
    property real micVolume: 0
    property bool micMuted: false
    property bool hasMic: false

    property var sinks: []       // [{ id, name, isDefault }]
    property var sources: []
    property var streams: []     // [{ id, name, app, volume, muted }]

    // Only one wpctl process per target; the last value is sent after the process finishes.
    property real pending: -1
    property real micPending: -1

    function refresh() {
        if (!statusProc.running && !setProc.running && !micProc.running) statusProc.running = true;
        if (!streamProc.running) streamProc.running = true;
    }

    function setVolume(v) {
        volume = Math.max(0, Math.min(1, v));
        pending = volume;
        if (!setProc.running) flush();
    }
    function flush() {
        if (pending < 0) return;
        setProc.command = ["wpctl", "set-volume", "-l", "1.0", sink, pending.toFixed(2)];
        pending = -1;
        setProc.running = true;
    }

    function setMicVolume(v) {
        micVolume = Math.max(0, Math.min(1, v));
        micPending = micVolume;
        if (!micProc.running) flushMic();
    }
    function flushMic() {
        if (micPending < 0) return;
        micProc.command = ["wpctl", "set-volume", "-l", "1.0", source, micPending.toFixed(2)];
        micPending = -1;
        micProc.running = true;
    }

    function toggleMute() {
        muted = !muted;
        Quickshell.execDetached(["wpctl", "set-mute", sink, "toggle"]);
    }
    function toggleMicMute() {
        micMuted = !micMuted;
        Quickshell.execDetached(["wpctl", "set-mute", source, "toggle"]);
    }

    function setStreamVolume(stream, v) {
        v = Math.max(0, Math.min(1, v));
        Quickshell.execDetached(["wpctl", "set-volume", String(stream.id), v.toFixed(2)]);
        streams = streams.map(s => s.id === stream.id ? Object.assign({}, s, { volume: v }) : s);
    }

    function toggleStreamMute(stream) {
        Quickshell.execDetached(["wpctl", "set-mute", String(stream.id), "toggle"]);
        streams = streams.map(s => s.id === stream.id ? Object.assign({}, s, { muted: !s.muted }) : s);
    }

    function setDefault(dev, isSink) {
        Quickshell.execDetached(["wpctl", "set-default", String(dev.id)]);
        const mark = list => list.map(d => Object.assign({}, d, { isDefault: d.id === dev.id }));
        if (isSink) sinks = mark(sinks); else sources = mark(sources);
    }

    function parseDevice(line) {
        const clean = line.replace(/[│├└─]/g, " ");
        const m = clean.match(/^\s*(\*)?\s*(\d+)\.\s+(.+?)\s*(\[vol:[^\]]*\])?\s*$/);
        return m ? { id: parseInt(m[2]), name: m[3], isDefault: m[1] === "*" } : null;
    }

    // Lines 1-2: get-volume sink & source; then S|… (sink) and R|… (source) from `wpctl status`
    readonly property string statusScript: [
        'echo "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"',
        'echo "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)"',
        'wpctl status 2>/dev/null | awk \'/^[A-Za-z]/ {a = ($1 == "Audio")}',
        '  a && /Sinks:/ {m = "S"; next}',
        '  a && /Sources:/ {m = "R"; next}',
        '  a && /(Devices|Filters|Streams):/ {m = ""; next}',
        '  a && m != "" && /[0-9]+\\./ {print m "|" $0}\''
    ].join("\n")

    Process {
        id: statusProc
        command: ["sh", "-c", root.statusScript]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");

                const v = (l[0] ?? "").match(/Volume:\s*([\d.]+)/);
                if (v) root.volume = Math.min(1, parseFloat(v[1]));
                root.muted = (l[0] ?? "").includes("[MUTED]");

                const mv = (l[1] ?? "").match(/Volume:\s*([\d.]+)/);
                root.hasMic = !!mv;
                if (mv) root.micVolume = Math.min(1, parseFloat(mv[1]));
                root.micMuted = (l[1] ?? "").includes("[MUTED]");

                const s = [], r = [];
                for (const line of l.slice(2)) {
                    const d = root.parseDevice(line.slice(2));
                    if (!d) continue;
                    if (line.startsWith("S|")) s.push(d);
                    else if (line.startsWith("R|")) r.push(d);
                }
                root.sinks = s;
                root.sources = r;
            }
        }
    }

    Process { id: setProc; onExited: root.flush() }
    Process { id: micProc; onExited: root.flushMic() }

    Process {
        id: streamProc
        command: ["wpctl", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const section = lines.findIndex(line => /Streams:\s*$/.test(line));
                if (section < 0) {
                    root.streams = [];
                    return;
                }

                const entries = [];
                for (let i = section + 1; i < lines.length; i++) {
                    const raw = lines[i];
                    if (raw.trim() === "") continue;
                    if (!/^[\s│├└─]/.test(raw)) break;
                    const clean = raw.replace(/[│├└─]/g, " ");
                    const match = clean.match(/^(\s*)(\d+)\.\s+(.+?)\s*$/);
                    if (!match) continue;
                    entries.push({ indent: match[1].length, id: parseInt(match[2]), text: match[3] });
                }

                if (entries.length === 0) {
                    root.streams = [];
                    return;
                }

                const level = Math.min(...entries.map(entry => entry.indent));
                root.streams = entries.filter(entry => entry.indent === level).map(entry => {
                    const volumeMatch = entry.text.match(/\[vol:\s*([\d.]+)\]/i);
                    return {
                        id: entry.id,
                        name: entry.text.replace(/\s*\[vol:[^\]]*\]/i, "").replace(/\s*\[MUTED\]/i, "").trim(),
                        app: "",
                        volume: volumeMatch ? Math.max(0, Math.min(1, parseFloat(volumeMatch[1]))) : 1,
                        muted: /\[MUTED\]/i.test(entry.text)
                    };
                });
            }
        }
    }

    Component.onCompleted: refresh()
}
