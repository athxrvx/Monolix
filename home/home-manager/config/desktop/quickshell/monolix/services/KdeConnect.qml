pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell.Io
import Quickshell
import QtQuick

Singleton {
    id: root

    property list<var> devices: []
    property string statusText: ""
    readonly property bool refreshing: refreshProcess.running || listProcess.running || actionProcess.running
    property string _listOutput: ""
    property string _actionOutput: ""
    property string _actionError: ""
    property string _pendingAction: ""

    function refresh(): void {
        if (refreshProcess.running || listProcess.running || actionProcess.running)
            return;
        statusText = qsTr("Searching for devices…");
        refreshProcess.running = true;
    }

    function listDevices(): void {
        if (listProcess.running)
            return;
        listProcess.running = true;
    }

    function parseDeviceList(output: string): void {
        const parsed = [];
        for (const line of output.split("\n")) {
            const match = line.match(/^\s*-\s*(.+?):\s*([a-fA-F0-9-]{16,})(.*)$/);
            if (!match)
                continue;

            const stateMatch = match[3].match(/\(([^()]*)\)\s*$/);
            const state = stateMatch ? stateMatch[1].toLowerCase() : "";
            parsed.push({
                id: match[2],
                name: match[1].trim(),
                paired: state.includes("paired"),
                reachable: state.includes("reachable")
            });
        }
        devices = parsed;
        statusText = parsed.length === 0
            ? qsTr("No devices found. Open KDE Connect on your phone, then refresh.")
            : (parsed.length === 1 ? qsTr("1 device found") : qsTr("%1 devices found").arg(parsed.length));
    }

    function runAction(deviceId: string, action: string): void {
        if (actionProcess.running)
            return;
        _pendingAction = action;
        _actionOutput = "";
        _actionError = "";
        actionProcess.command = ["kdeconnect-cli", "--device", deviceId, action];
        actionProcess.running = true;
    }

    Process {
        id: refreshProcess
        command: ["kdeconnect-cli", "--refresh"]
        running: false
        onExited: root.listDevices()
    }

    Process {
        id: listProcess
        command: ["kdeconnect-cli", "--list-devices"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._listOutput = text
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.parseDeviceList(root._listOutput);
            } else {
                root.devices = [];
                root.statusText = qsTr("KDE Connect is not running yet.");
            }
        }
    }

    Process {
        id: actionProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._actionOutput = text
        }
        stderr: StdioCollector {
            onStreamFinished: root._actionError = text
        }
        onExited: (exitCode, exitStatus) => {
            root.statusText = exitCode === 0
                ? (root._actionOutput.trim() || qsTr("KDE Connect action sent"))
                : (root._actionError.trim() || qsTr("Could not complete KDE Connect action"));
            followupTimer.restart();
        }
    }

    Timer {
        id: followupTimer
        interval: 1200
        onTriggered: root.listDevices()
    }

    Component.onCompleted: refresh()
}
