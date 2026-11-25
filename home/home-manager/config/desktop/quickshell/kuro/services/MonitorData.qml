pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Samples used by the standalone monitor. Polling runs only while its window is visible.
Singleton {
    id: root

    property bool active: false
    property int revision: 0
    property real cpu: 0
    property real memory: 0
    property real diskRate: 0
    property real diskLevel: 0
    property real networkRate: 0
    property real networkLevel: 0
    property real gpu: 0
    property bool networkConnected: false
    property var cpuHistory: []
    property var memoryHistory: []
    property var diskHistory: []
    property var networkHistory: []
    property var gpuHistory: []
    property var filesystems: []
    property string logs: ""
    property string detailError: ""

    property var previousCpu: null
    property var previousNetwork: null
    property real diskPeak: 500000
    property real networkPeak: 100000
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
        cpu = 0; memory = 0; diskRate = 0; diskLevel = 0; networkRate = 0; networkLevel = 0; gpu = 0;
        networkConnected = false;
        previousCpu = null; previousDisk = null; previousNetwork = null;
        diskPeak = 500000; networkPeak = 100000;
        cpuHistory = []; memoryHistory = []; diskHistory = []; networkHistory = []; gpuHistory = [];
        revision++;
    }

    function historyFor(metric) {
        switch (metric) {
        case "cpu": return cpuHistory;
        case "memory": return memoryHistory;
        case "disk": return diskHistory;
        case "network": return networkHistory;
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

    function refreshPage(page) {
        detailError = "";
        if (page === "storage" && !storageProc.running) storageProc.running = true;
        else if (page === "logs" && !logsProc.running) logsProc.running = true;
        else if (page === "hardware") {
            SystemInfo.refresh();
            SystemStats.refresh();
            GpuStatus.refresh(true);
        }
    }

    Timer {
        id: sampleTimer
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sample()
    }

    Process {
        id: proc
        command: ["python3", Config.systemWindowDataScript, "performance"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.active) return;
                let data;
                try { data = JSON.parse(text); }
                catch (error) { root.detailError = "Could not parse performance data."; return; }
                if (data.error) { root.detailError = data.error; return; }
                root.detailError = "";
                const now = Date.now();

                const total = Number(data.cpu?.total) || 0;
                const idle = Number(data.cpu?.idle) || 0;
                let cpuValue = root.cpu;
                if (root.previousCpu && total > root.previousCpu.total) {
                    const totalDelta = total - root.previousCpu.total;
                    cpuValue = Math.max(0, Math.min(1, 1 - (idle - root.previousCpu.idle) / totalDelta));
                }
                root.previousCpu = { total: total, idle: idle };
                root.cpu = cpuValue;
                root.cpuHistory = root.append(root.cpuHistory, cpuValue);

                const memTotal = Number(data.memory?.total) || 0;
                const memAvailable = Number(data.memory?.available) || 0;
                root.memory = memTotal > 0 ? Math.max(0, Math.min(1, (memTotal - memAvailable) / memTotal)) : 0;
                root.memoryHistory = root.append(root.memoryHistory, root.memory);

                const readSectors = Number(data.disk?.readSectors) || 0;
                const writtenSectors = Number(data.disk?.writtenSectors) || 0;
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

                const iface = data.network?.interface ?? "";
                const rx = Number(data.network?.rx) || 0;
                const tx = Number(data.network?.tx) || 0;
                root.networkConnected = iface !== "";
                let rate = 0;
                if (root.previousNetwork && iface !== "" && iface === root.previousNetwork.iface) {
                    const seconds = Math.max(0.001, (now - root.previousNetwork.time) / 1000);
                    rate = (Math.max(0, rx - root.previousNetwork.rx) + Math.max(0, tx - root.previousNetwork.tx)) / seconds;
                }
                root.previousNetwork = iface !== "" ? { iface: iface, rx: rx, tx: tx, time: now } : null;
                root.networkRate = rate;
                root.networkPeak = Math.max(rate, root.networkPeak * 0.97, 100000);
                root.networkLevel = Math.min(1, rate / root.networkPeak);
                root.networkHistory = root.append(root.networkHistory, root.networkLevel);

                root.gpu = GpuStatus.available ? Math.max(0, Math.min(1, GpuStatus.utilization / 100)) : 0;
                root.gpuHistory = root.append(root.gpuHistory, root.gpu);
                root.revision++;
            }
        }
    }

    Process {
        id: storageProc
        command: ["python3", Config.systemWindowDataScript, "storage"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.detailError = data.error ?? "";
                    root.filesystems = data.filesystems ?? [];
                } catch (error) { root.detailError = "Could not parse storage data."; }
            }
        }
    }

    Process {
        id: logsProc
        command: ["python3", Config.systemWindowDataScript, "logs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.detailError = data.error ?? "";
                    root.logs = data.logs ?? "";
                } catch (error) { root.detailError = "Could not parse journal data."; }
            }
        }
    }
}
