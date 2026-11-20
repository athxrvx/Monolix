pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// NetworkManager state and Wi-Fi actions used by the bar and Network page.
Singleton {
    id: root

    property bool enabled: false
    property bool busy: false
    property string wifiDevice: ""
    property string ssid: ""
    property int wifiSignal: 0
    property string wifiIp: ""

    property string ethDevice: ""
    property bool ethConnected: false
    property string ethIp: ""
    property string ethSpeed: ""
    readonly property bool online: ethConnected || ssid !== ""

    property var networks: []
    property bool scanning: false
    property string connecting: ""
    property var connectingNet: null
    // SSID whose saved credentials failed; the UI must ask for a new PSK.
    property string reauthSsid: ""
    property string error: ""
    property bool scanAfterStatus: false

    // nmcli terse output escapes its delimiters with backslashes.
    function fields(value, separator) {
        const values = [];
        let part = "", escaped = false;
        for (const ch of (value ?? "")) {
            if (escaped) { part += ch; escaped = false; }
            else if (ch === "\\") escaped = true;
            else if (ch === separator) { values.push(part); part = ""; }
            else part += ch;
        }
        if (escaped) part += "\\";
        values.push(part);
        return values;
    }

    function refresh(withScan) {
        if (withScan) scanAfterStatus = true;
        if (!statusProc.running) statusProc.running = true;
    }

    function toggle() {
        if (busy) return;
        error = "";
        busy = true;
        toggleProc.targetEnabled = !enabled;
        scanAfterStatus = toggleProc.targetEnabled;
        toggleProc.errorText = "";
        toggleProc.command = ["nmcli", "radio", "wifi", toggleProc.targetEnabled ? "on" : "off"];
        toggleProc.running = true;
    }

    function scan(force) {
        if (!enabled || scanning) return;
        error = "";
        scanning = true;
        scanProc.stderrText = "";
        scanProc.command = ["sh", "-c", scanScript, "sh", force ? "yes" : "auto"];
        scanProc.running = true;
    }

    function connect(net, password) {
        if (!net || !net.ssid || connecting !== "") return;
        const reauth = reauthSsid === net.ssid;
        if (net.secure && (!net.known || reauth) && !(password ?? "")) {
            error = "Enter the Wi-Fi password to connect.";
            return;
        }
        error = "";
        connecting = net.ssid;
        connectingNet = net;
        connectProc.errorText = "";
        connectProc.stdoutText = "";
        // A saved profile with a stale PSK needs its secret replaced, not just
        // another "connection up" (which would keep failing silently).
        connectProc.command = reauth && net.uuid && password
            ? ["sh", "-c", updatePskScript, "sh", net.uuid, password, wifiDevice]
            : net.known
                ? (wifiDevice
                    ? ["nmcli", "--wait", "30", "connection", "up", "uuid", net.uuid, "ifname", wifiDevice]
                    : ["nmcli", "--wait", "30", "connection", "up", "uuid", net.uuid])
                : net.secure
                    ? (wifiDevice
                        ? ["nmcli", "--wait", "30", "device", "wifi", "connect", net.ssid, "password", password, "ifname", wifiDevice]
                        : ["nmcli", "--wait", "30", "device", "wifi", "connect", net.ssid, "password", password])
                    : (wifiDevice
                        ? ["nmcli", "--wait", "30", "device", "wifi", "connect", net.ssid, "ifname", wifiDevice]
                        : ["nmcli", "--wait", "30", "device", "wifi", "connect", net.ssid]);
        connectProc.running = true;
    }

    function disconnect() {
        if (!wifiDevice || connecting !== "") return;
        connecting = ssid || "Wi-Fi";
        connectingNet = null;
        connectProc.errorText = "";
        connectProc.stdoutText = "";
        connectProc.command = ["nmcli", "device", "disconnect", wifiDevice];
        connectProc.running = true;
    }

    // Replace the PSK on an existing profile and activate it. Arguments are
    // passed as argv ($1..$3) so passwords with shell metacharacters are safe.
    readonly property string updatePskScript: [
        'uuid="$1"; pass="$2"; dev="$3"',
        'nmcli connection modify uuid "$uuid" 802-11-wireless-security.psk "$pass" 802-11-wireless-security.psk-flags 0 || exit $?',
        'if [ -n "$dev" ]; then exec nmcli --wait 30 connection up uuid "$uuid" ifname "$dev"; fi',
        'exec nmcli --wait 30 connection up uuid "$uuid"'
    ].join("\n")

    readonly property string statusScript: [
        'radio=$(nmcli -t radio wifi 2>/dev/null)',
        'dev=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null)',
        'w=$(printf "%s\\n" "$dev" | awk -F: \'$2=="wifi" && $3 ~ /^connected/ {print $1; exit}\')',
        'e=$(printf "%s\\n" "$dev" | awk -F: \'$2=="ethernet" {print; if ($3 ~ /^connected/) exit}\' | tail -n1)',
        'printf "%s\\n%s\\n" "$radio" "$w"',
        '[ -n "$w" ] && nmcli -g GENERAL.CONNECTION device show "$w" 2>/dev/null || true',
        '[ -n "$w" ] && nmcli -t --escape no -f IN-USE,SIGNAL device wifi list --rescan no 2>/dev/null | awk -F: \'$1=="*" {print $2; exit}\' || true',
        '[ -n "$w" ] && ip -4 -o addr show dev "$w" 2>/dev/null | awk \'{print $4; exit}\' || true',
        'printf "%s\\n%s\\n" "${e%%:*}" "${e#*:}"',
        '[ -n "$e" ] && ip -4 -o addr show dev "${e%%:*}" 2>/dev/null | awk \'{print $4; exit}\' || true',
        '[ -n "$e" ] && cat "/sys/class/net/${e%%:*}/speed" 2>/dev/null || true'
    ].join("\n")

    Process {
        id: statusProc
        command: ["sh", "-c", root.statusScript]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                root.enabled = l[0] === "enabled";
                root.wifiDevice = l[1] ?? "";
                root.ssid = root.enabled ? (l[2] ?? "") : "";
                root.wifiSignal = root.ssid !== "" ? Math.max(0, Math.min(100, parseInt(l[3]) || 0)) : 0;
                root.wifiIp = l[4] ?? "";
                root.ethDevice = l[5] ?? "";
                root.ethConnected = /^connected/.test(l[6] ?? "");
                root.ethIp = l[7] ?? "";
                const speed = parseInt(l[8]);
                root.ethSpeed = speed > 0 ? (speed >= 1000 ? speed / 1000 + " Gb/s" : speed + " Mb/s") : "";
                if (root.scanAfterStatus && !root.busy) {
                    root.scanAfterStatus = false;
                    if (root.enabled) root.scan(false);
                }
            }
        }
    }

    Process {
        id: toggleProc
        property bool targetEnabled: false
        property string errorText: ""
        stderr: StdioCollector { onStreamFinished: toggleProc.errorText = text.trim() }
        onExited: (code, status) => {
            root.busy = false;
            if (code !== 0) root.error = errorText || "Could not change Wi-Fi state.";
            root.refresh();
            if (code === 0 && targetEnabled) root.scanAfterStatus = true;
            if (code === 0 && !targetEnabled) {
                root.networks = [];
                root.reauthSsid = "";
            }
        }
    }

    // Output records: N|IN-USE:SIGNAL:SECURITY:SSID, K|SSID|UUID.
    readonly property string scanScript: [
        'list=$(timeout 20 nmcli -t --escape yes -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan "$1" 2>&1)',
        'rc=$?',
        'if [ "$rc" -ne 0 ]; then printf "%s\\n" "$list" >&2; exit "$rc"; fi',
        'printf "%s\\n" "$list" | sed "s/^/N|/"',
        'nmcli -t --escape yes -f UUID,TYPE connection show 2>/dev/null | while IFS= read -r row; do',
        '  case "$row" in *:802-11-wireless)',
        '    uuid=${row%:*}',
        '    ssid=$(nmcli -g 802-11-wireless.ssid connection show uuid "$uuid" 2>/dev/null)',
        '    [ -n "$ssid" ] && printf "K|%s|%s\\n" "$ssid" "$uuid";;',
        '  esac',
        'done'
    ].join("\n")

    Process {
        id: scanProc
        property string stderrText: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = {};
                const aps = {};
                const lines = text.split("\n");
                for (const line of lines) {
                    if (!line.startsWith("K|")) continue;
                    const record = line.slice(2);
                    const sep = record.lastIndexOf("|");
                    if (sep < 0) continue;
                    const name = record.slice(0, sep);
                    const uuid = record.slice(sep + 1);
                    if (name && uuid && !saved[name]) saved[name] = uuid;
                }
                for (const line of lines) {
                    if (!line.startsWith("N|")) continue;
                    const f = root.fields(line.slice(2), ":");
                    if (f.length < 4) continue;
                    const name = f.slice(3).join(":");
                    if (!name) continue;
                    const sec = f[2];
                    const item = {
                        ssid: name,
                        signal: parseInt(f[1]) || 0,
                        security: !sec || sec === "--" ? "Open network" : sec,
                        secure: !!sec && sec !== "--",
                        active: f[0].trim() === "*",
                        known: saved[name] !== undefined,
                        uuid: saved[name] ?? ""
                    };
                    if (!aps[name] || item.active || (!aps[name].active && item.signal > aps[name].signal))
                        aps[name] = item;
                }
                root.networks = Object.values(aps).sort((a, b) =>
                    Number(b.active) - Number(a.active) || Number(b.known) - Number(a.known) || b.signal - a.signal);
            }
        }
        stderr: StdioCollector { onStreamFinished: scanProc.stderrText = text.trim() }
        onExited: (code, status) => {
            root.scanning = false;
            if (code !== 0) root.error = stderrText.split("\n").slice(-1)[0] || "Wi-Fi scan failed.";
        }
    }

    Process {
        id: connectProc
        property string errorText: ""
        property string stdoutText: ""
        stdout: StdioCollector { onStreamFinished: connectProc.stdoutText = text.trim() }
        stderr: StdioCollector { onStreamFinished: connectProc.errorText = text.trim() }
        onExited: (code, status) => {
            const ssid = root.connecting;
            const net = root.connectingNet;
            const detail = (connectProc.errorText || connectProc.stdoutText || "")
                .split("\n").map(s => s.trim()).filter(Boolean).slice(-1)[0] || "";
            root.connecting = "";
            root.connectingNet = null;
            if (code === 0) {
                if (root.reauthSsid === ssid) root.reauthSsid = "";
                root.error = "";
            } else {
                // Any failure activating a saved secure profile is treated as
                // a possible password change: ask for a fresh PSK instead of
                // spinning on "Connecting…" with stale credentials.
                if (net && net.known && net.secure && !root.reauthSsid) {
                    root.reauthSsid = ssid;
                    root.error = "Saved password didn't work for " + ssid + ". Enter the new password."
                        + (detail ? " " + detail : "");
                } else {
                    root.error = detail || "Could not connect to the selected network.";
                }
            }
            root.refresh();
            root.scan(false);
        }
    }

    Component.onCompleted: refresh()
}
