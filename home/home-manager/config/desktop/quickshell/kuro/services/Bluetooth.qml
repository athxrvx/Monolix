pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Bluetooth via bluetoothctl: power, paired devices, connect/disconnect.
// `timeout` prevents bluetoothctl from hanging if bluetoothd isn't running.
Singleton {
    id: root

    property bool available: false
    property bool powered: false
    property string device: ""        // name of the first connected device
    property var devices: []          // [{ mac, name, connected, paired }]
    property string pending: ""       // MAC currently being connected/disconnected
    property bool busy: false
    property bool scanning: false
    property string error: ""

    function refresh() {
        if (!statusProc.running && !busy) statusProc.running = true;
    }

    function toggle() {
        if (busy || !available) return;
        error = "";
        busy = true;
        const target = !powered;
        powered = target;
        if (!target) device = "";
        toggleProc.command = target
            ? ["sh", "-c", "rfkill unblock bluetooth; sleep 0.3; timeout 5 bluetoothctl power on"]
            : ["timeout", "5", "bluetoothctl", "power", "off"];
        toggleProc.outputText = "";
        toggleProc.errorText = "";
        toggleProc.running = true;
    }

    function toggleDevice(d) {
        if (devProc.running || !powered || !d || !/^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/.test(d.mac)) return;
        error = "";
        pending = d.mac;
        devProc.outputText = "";
        devProc.errorText = "";
        devProc.command = d.connected
            ? ["timeout", "10", "bluetoothctl", "disconnect", d.mac]
            : d.paired
                ? ["timeout", "15", "bluetoothctl", "connect", d.mac]
                : ["sh", "-c", "timeout 15 bluetoothctl pair \"$1\" && timeout 5 bluetoothctl trust \"$1\" && timeout 15 bluetoothctl connect \"$1\"", "sh", d.mac];
        devProc.running = true;
    }

    function scan() {
        if (!powered || scanning) return;
        error = "";
        scanning = true;
        scanProc.errorText = "";
        // Keep one bluetoothctl session alive for the full discovery window.
        // Starting `scan on` and immediately exiting can stop discovery before
        // nearby devices have time to appear.
        scanProc.command = ["sh", "-c",
            "{ printf 'scan on\\n'; sleep 8; printf 'scan off\\ndevices\\n'; sleep 1; } | timeout 12 bluetoothctl"];
        scanProc.running = true;
    }

    // Line 1: Powered yes/no (empty = no adapter), then C|MAC Name and P|MAC Name
    readonly property string statusScript: [
        'echo "$(timeout 3 bluetoothctl show 2>/dev/null | awk \'/Powered:/ {print $2; exit}\')"',
        'timeout 3 bluetoothctl devices Connected 2>/dev/null | sed -n "s/^Device /C|/p"',
        '{ timeout 3 bluetoothctl devices Paired 2>/dev/null || timeout 3 bluetoothctl paired-devices 2>/dev/null; } | sed -n "s/^Device /P|/p"'
    ].join("\n")

    Process {
        id: statusProc
        command: ["sh", "-c", root.statusScript]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const state = (lines[0] ?? "").trim();
                root.available = state === "yes" || state === "no";
                root.powered = state === "yes";

                const map = {};
                const connected = {};
                for (const l of lines) {
                    if (!l.startsWith("C|") && !l.startsWith("P|")) continue;
                    const rest = l.slice(2);
                    const mac = rest.split(" ")[0];
                    const name = rest.slice(mac.length + 1) || mac;
                    if (l.startsWith("C|")) connected[mac] = true;
                    map[mac] = { mac: mac, name: name, connected: false, paired: l.startsWith("P|") };
                }
                // Keep discovered, unpaired devices between status polls.
                for (const d of root.devices)
                    if (!d.paired && !d.connected && !map[d.mac]) map[d.mac] = d;
                for (const mac in connected) if (map[mac]) map[mac].connected = true;

                root.devices = Object.values(map).sort((a, b) =>
                    (b.connected - a.connected) || a.name.localeCompare(b.name));
                const first = root.devices.find(d => d.connected);
                root.device = root.powered && first ? first.name : "";
            }
        }
    }

    Process {
        id: toggleProc
        property string outputText: ""
        property string errorText: ""
        stdout: StdioCollector { onStreamFinished: toggleProc.outputText = text.trim() }
        stderr: StdioCollector { onStreamFinished: toggleProc.errorText = text.trim() }
        onExited: (code, status) => {
            root.busy = false;
            const details = toggleProc.errorText || toggleProc.outputText;
            if (code !== 0 || /failed|error|not available/i.test(details))
                root.error = details.split("\n").filter(Boolean).pop()
                    || "Could not change Bluetooth power state.";
            root.refresh();
        }
    }

    Process {
        id: devProc
        property string outputText: ""
        property string errorText: ""
        stdout: StdioCollector { onStreamFinished: devProc.outputText = text.trim() }
        stderr: StdioCollector { onStreamFinished: devProc.errorText = text.trim() }
        onExited: (code, status) => {
            root.pending = "";
            const details = (devProc.errorText || devProc.outputText).split("\n").filter(Boolean).pop() ?? "";
            if (code !== 0 || /failed|error|not available/i.test(details))
                root.error = details || "Device action failed. Check that the device is in pairing mode and nearby.";
            root.refresh();
        }
    }

    Process {
        id: scanProc
        property string errorText: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const found = {};
                for (const d of root.devices) found[d.mac] = d;
                const lines = text.split("\n");
                for (const line of lines) {
                    const match = line.match(/^Device\s+(([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2})\s+(.+)$/);
                    if (!match) continue;
                    const previous = found[match[1]];
                    found[match[1]] = {
                        mac: match[1], name: match[3],
                        connected: previous?.connected ?? false,
                        paired: previous?.paired ?? false
                    };
                }
                root.devices = Object.values(found).sort((a, b) =>
                    (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name));
            }
        }
        stderr: StdioCollector { onStreamFinished: scanProc.errorText = text.trim() }
        onExited: (code, status) => {
            root.scanning = false;
            if (root.devices.length === 0 && scanProc.errorText)
                root.error = scanProc.errorText.split("\n").filter(Boolean).pop();
            else if (code !== 0 && root.devices.length === 0)
                root.error = scanProc.errorText || "Bluetooth scan failed. Check that the adapter is available.";
        }
    }

    Component.onCompleted: refresh()
}
