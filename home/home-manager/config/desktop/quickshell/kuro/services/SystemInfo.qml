pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Hardware and host inventory returned as JSON by bin/system-window-data.py.
Singleton {
    id: root

    property string user: Quickshell.env("USER") ?? "user"
    property string host: "localhost"
    property string uptime: ""
    property string kernel: ""
    property string os: ""
    property string compositor: ""
    property string resolution: ""
    property string cpu: ""
    property var monitors: []
    property var gpus: []
    property var disks: []
    property var platformInfo: ({})
    property string error: ""

    function refresh() {
        if (!dataProc.running) dataProc.running = true;
    }

    function refreshHardware() { refresh(); }

    function formatUptime(seconds) {
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor(seconds % 86400 / 3600);
        const minutes = Math.floor(seconds % 3600 / 60);
        return days > 0 ? days + "d " + hours + "h" : hours + "h " + minutes + "m";
    }

    Process {
        id: dataProc
        command: ["python3", Config.systemWindowDataScript, "hardware"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data.error) { root.error = data.error; return; }
                    root.error = "";
                    root.host = data.host ?? "";
                    root.uptime = root.formatUptime(data.uptimeSeconds ?? 0);
                    root.kernel = data.kernel ?? "";
                    root.os = data.os ?? "";
                    root.compositor = data.compositor ?? "";
                    root.cpu = data.cpu ?? "";
                    root.monitors = data.monitors ?? [];
                    root.resolution = root.monitors.map(m => m.resolution + " @ " + m.refresh + "Hz").join(" · ");
                    root.gpus = data.gpus ?? [];
                    root.disks = data.disks ?? [];
                    root.platformInfo = data.platform ?? {};
                } catch (error) {
                    root.error = "Could not parse system inventory.";
                }
            }
        }
    }

    Component.onCompleted: refresh()
}
