pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Samples used by the standalone monitor. Polling runs only while its window is visible.
Singleton {
    id: root

    property bool active: false
    property int revision: 0
    property real cpu: 0
    property real memory: 0
    property real diskRate: 0
    property real diskLevel: 0
    property real wifiRate: 0
    property real wifiLevel: 0
    property real gpu: 0
    property bool wifiConnected: false
    property var cpuHistory: []
    property var memoryHistory: []
    property var diskHistory: []
    property var wifiHistory: []
    property var gpuHistory: []

    property var previousCpu: null
    property var previousWifi: null
    property real diskPeak: 500000
    property real wifiPeak: 100000
    property var previousDisk: null

    function setActive(value) {
        if (active === value) return;
        active = value;
        sampleTimer.stop();
        if (!active) {
            clearHistory();
            return;
        }
        clearHistory();
        sampleTimer.start();
    }

    function clearHistory() {
        cpu = 0; memory = 0; diskRate = 0; diskLevel = 0; wifiRate = 0; wifiLevel = 0; gpu = 0;
        wifiConnected = false;
        previousCpu = null; previousDisk = null; previousWifi = null;
        diskPeak = 500000; wifiPeak = 100000;
        cpuHistory = []; memoryHistory = []; diskHistory = []; wifiHistory = []; gpuHistory = [];
        revision++;
    }

    function historyFor(metric) {
        switch (metric) {
        case "cpu": return cpuHistory;
        case "memory": return memoryHistory;
        case "disk": return diskHistory;
        case "wifi": return wifiHistory;
        case "gpu": return gpuHistory;
        default: return [];
        }
    }

    function append(values, value) {
        const next = values.slice(-59);
        next.push(Math.max(0, Math.min(1, value)));
        return next;
    }

    function sample() {
        if (!active || proc.running) return;
        GpuStatus.refresh();
        proc.running = true;
    }

    function formatRate(bytesPerSecond) {
        const bits = bytesPerSecond * 8;
        if (bits >= 1000000) return (bits / 1000000).toFixed(1) + " Mb/s";
        if (bits >= 1000) return Math.round(bits / 1000) + " Kb/s";
        return Math.round(bits) + " b/s";
    }

    readonly property string script: [
        "awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8,$9; exit}' /proc/stat",
        "awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print t+0,a+0}' /proc/meminfo",
        "awk '$3 ~ /^(nvme[0-9]+n[0-9]+|sd[a-z]+|vd[a-z]+|xvd[a-z]+|mmcblk[0-9]+)$/ {r+=$6; w+=$10} END{print r+0,w+0}' /proc/diskstats",
        'wifi=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | awk -F: \'$2=="wifi" && $3 ~ /^connected/ {print $1; exit}\')',
        'if [ -n "$wifi" ]; then printf "%s\\n" "$wifi"; cat "/sys/class/net/$wifi/statistics/rx_bytes" "/sys/class/net/$wifi/statistics/tx_bytes" 2>/dev/null | xargs; else printf "\\n0 0\\n"; fi'
    ].join("\n")

    Timer {
        id: sampleTimer
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sample()
    }

    Process {
        id: proc
        command: ["sh", "-c", root.script]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.active) return;
                const lines = text.trimEnd().split("\n");
                const now = Date.now();

                const c = (lines[0] ?? "").trim().split(/\s+/).map(Number);
                const idle = (c[3] || 0) + (c[4] || 0);
                const total = c.reduce((sum, value) => sum + (value || 0), 0);
                let cpuValue = root.cpu;
                if (root.previousCpu && total > root.previousCpu.total) {
                    const totalDelta = total - root.previousCpu.total;
                    cpuValue = Math.max(0, Math.min(1, 1 - (idle - root.previousCpu.idle) / totalDelta));
                }
                root.previousCpu = { total: total, idle: idle };
                root.cpu = cpuValue;
                root.cpuHistory = root.append(root.cpuHistory, cpuValue);

                const mem = (lines[1] ?? "").trim().split(/\s+/).map(Number);
                const memTotal = mem[0] || 0;
                const memAvailable = mem[1] || 0;
                root.memory = memTotal > 0 ? Math.max(0, Math.min(1, (memTotal - memAvailable) / memTotal)) : 0;
                root.memoryHistory = root.append(root.memoryHistory, root.memory);

                const disk = (lines[2] ?? "").trim().split(/\s+/).map(Number);
                const readSectors = disk[0] || 0, writtenSectors = disk[1] || 0;
                let diskRate = 0;
                if (root.previousDisk) {
                    const seconds = Math.max(0.001, (now - root.previousDisk.time) / 1000);
                    diskRate = (Math.max(0, readSectors - root.previousDisk.read) +
                                Math.max(0, writtenSectors - root.previousDisk.written)) * 512 / seconds;
                }
                root.previousDisk = { read: readSectors, written: writtenSectors, time: now };
                root.diskRate = diskRate;
                root.diskPeak = Math.max(diskRate, root.diskPeak * 0.97, 500000);
                root.diskLevel = Math.min(1, diskRate / root.diskPeak);
                root.diskHistory = root.append(root.diskHistory, root.diskLevel);

                const iface = (lines[3] ?? "").trim();
                const net = (lines[4] ?? "").trim().split(/\s+/).map(Number);
                const rx = net[0] || 0, tx = net[1] || 0;
                root.wifiConnected = iface !== "";
                let rate = 0;
                if (root.previousWifi && iface !== "" && iface === root.previousWifi.iface) {
                    const seconds = Math.max(0.001, (now - root.previousWifi.time) / 1000);
                    rate = (Math.max(0, rx - root.previousWifi.rx) + Math.max(0, tx - root.previousWifi.tx)) / seconds;
                }
                root.previousWifi = iface !== "" ? { iface: iface, rx: rx, tx: tx, time: now } : null;
                root.wifiRate = rate;
                root.wifiPeak = Math.max(rate, root.wifiPeak * 0.97, 100000);
                root.wifiLevel = Math.min(1, rate / root.wifiPeak);
                root.wifiHistory = root.append(root.wifiHistory, root.wifiLevel);

                root.gpu = GpuStatus.available ? Math.max(0, Math.min(1, GpuStatus.utilization / 100)) : 0;
                root.gpuHistory = root.append(root.gpuHistory, root.gpu);
                root.revision++;
            }
        }
    }
}
