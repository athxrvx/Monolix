
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Power mode via D-Bus (works with both tuned-ppd and power-profiles-daemon).
Singleton {
    id: root

    property bool available: false
    property string current: ""
    property var profiles: []        // e.g. ["power-saver", "balanced", "performance"]
    property bool applying: false
    property string error: ""
    property bool refreshPending: false

    property string busDest: "org.freedesktop.UPower.PowerProfiles"
    property string busPath: "/org/freedesktop/UPower/PowerProfiles"
    property string busIface: "org.freedesktop.UPower.PowerProfiles"

    function refresh() {
        if (setProc.running || proc.running) {
            refreshPending = true;
            return;
        }
        proc.running = true;
    }

    function refreshQueued() {
        if (!refreshPending || setProc.running) return;
        refreshTimer.restart();
    }

    function set(p) {
        if (!available || profiles.indexOf(p) < 0 || setProc.running || p === current) return;
        error = "";
        applying = true;
        setProc.errorText = "";
        setProc.command = [
            "busctl", "set-property",
            root.busDest, root.busPath, root.busIface,
            "ActiveProfile", "s", p
        ];
        setProc.running = true;
    }

    function pretty(p) {
        return { "power-saver": "Power saver", "balanced": "Balanced", "performance": "Performance" }[p] ?? p;
    }

    readonly property string script: [
        'command -v busctl >/dev/null || exit 0',
        'dest="org.freedesktop.UPower.PowerProfiles"',
        'path="/org/freedesktop/UPower/PowerProfiles"',
        'iface="org.freedesktop.UPower.PowerProfiles"',
        'if ! busctl get-property "$dest" "$path" "$iface" ActiveProfile >/dev/null 2>&1; then',
        '  dest="net.hadess.PowerProfiles"',
        '  path="/net/hadess/PowerProfiles"',
        '  iface="net.hadess.PowerProfiles"',
        'fi',
        'current=$(busctl get-property "$dest" "$path" "$iface" ActiveProfile 2>/dev/null | sed -nE \'s/^s "([^"]+)"$/\\1/p\') || exit 0',
        '[ -n "$current" ] || exit 0',
        'echo "$dest|$path|$iface"',
        'echo "$current"',
        'busctl get-property "$dest" "$path" "$iface" Profiles 2>/dev/null | grep -oE \'"Profile" s "[^"]+"\' | sed -nE \'s/^"Profile" s "([^"]+)"$/\\1/p\''
    ].join("\n")

    Process {
        id: proc
        command: ["sh", "-c", root.script]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                if (l.length < 3) {
                    root.available = false;
                    root.current = "";
                    root.profiles = [];
                    root.refreshQueued();
                    return;
                }

                const busInfo = l[0].split("|");
                if (busInfo.length === 3) {
                    root.busDest = busInfo[0];
                    root.busPath = busInfo[1];
                    root.busIface = busInfo[2];
                }

                const currentProfile = l[1];
                const profiles = [...new Set(l.slice(2).filter(p => p !== ""))];
                root.available = currentProfile !== "none" && currentProfile !== "" && profiles.length > 0;

                if (!root.available) {
                    root.current = "";
                    root.profiles = [];
                    root.refreshQueued();
                    return;
                }

                root.current = currentProfile;
                root.profiles = profiles;
                root.refreshQueued();
            }
        }
    }

    Process {
        id: setProc
        property string errorText: ""
        stderr: StdioCollector { onStreamFinished: setProc.errorText = text.trim() }
        onExited: (code, status) => {
            root.applying = false;
            if (code !== 0) root.error = errorText || "Could not switch power profile";
            root.refreshPending = false;
            root.refresh();
        }
    }

    Timer {
        id: refreshTimer
        interval: 80
        repeat: false
        onTriggered: {
            if (!root.refreshPending || setProc.running) return;
            if (proc.running) { refreshTimer.restart(); return; }
            root.refreshPending = false;
            root.refresh();
        }
    }

    Component.onCompleted: refresh()
}
