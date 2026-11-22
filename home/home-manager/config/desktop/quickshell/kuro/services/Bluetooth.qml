pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth via Quickshell's native BlueZ API (DBus).
//
// State is pushed by BlueZ, so there is no polling and no bluetoothctl output
// parsing. The public shape matches what the bar, popup, control center and
// launcher already expect.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool powered: adapter?.enabled ?? false
    readonly property bool scanning: adapter?.discovering ?? false
    readonly property bool busy: adapter !== null
        && (adapter.state === BluetoothAdapterState.Enabling
            || adapter.state === BluetoothAdapterState.Disabling)

    // Plain objects keep the { mac, name, connected, paired } shape used by
    // existing delegates. Reading device properties in the binding makes it
    // re-evaluate when a device connects, pairs or changes name.
    readonly property var devices: {
        const list = [...Bluetooth.devices.values].map(d => ({
            mac: d.address,
            name: d.name || d.deviceName || d.address,
            connected: d.connected,
            paired: d.paired
        }));
        list.sort((a, b) => (b.connected - a.connected)
            || (b.paired - a.paired)
            || a.name.localeCompare(b.name));
        return list;
    }

    readonly property string device: {
        const d = devices.find(d => d.connected);
        return powered && d ? d.name : "";
    }

    // Address of the device currently connecting, disconnecting or pairing.
    readonly property string pending: {
        for (const d of Bluetooth.devices.values) {
            if (d.state === BluetoothDeviceState.Connecting
                || d.state === BluetoothDeviceState.Disconnecting
                || d.pairing)
                return d.address;
        }
        return "";
    }

    property string error: ""
    property var pairingDevice: null

    // Kept for existing call sites; BlueZ updates are reactive.
    function refresh() {}

    function toggle() {
        if (!adapter) return;
        if (adapter.state === BluetoothAdapterState.Blocked) {
            error = "Bluetooth is blocked by rfkill. Run: rfkill unblock bluetooth";
            return;
        }
        error = "";
        adapter.enabled = !adapter.enabled;
    }

    function scan() {
        if (!adapter || !adapter.enabled || adapter.discovering) return;
        error = "";
        adapter.discovering = true;
        scanTimer.restart();
    }

    function toggleDevice(d) {
        if (!adapter || !adapter.enabled || !d) return;
        const dev = deviceFor(d.mac);
        if (!dev) {
            error = "Device is no longer available.";
            return;
        }
        error = "";
        if (dev.connected) dev.disconnect();
        else if (dev.paired) dev.connect();
        else {
            // BlueZ falls back to a NoInputNoOutput (Just Works) agent when no
            // agent is registered, so pairing works without bluetoothctl.
            pairingDevice = dev;
            dev.trusted = true;
            dev.pair();
        }
    }

    function deviceFor(mac) {
        for (const d of Bluetooth.devices.values)
            if (d.address === mac) return d;
        return null;
    }

    // BlueZ keeps discovering until a client stops it; keep a ~10s scan window.
    Timer {
        id: scanTimer
        interval: 10000
        onTriggered: if (root.adapter) root.adapter.discovering = false
    }

    // Pairing is asynchronous. Connect once it succeeds; only report failure
    // after the state settles so a late Paired update is not misread.
    Timer {
        id: pairSettleTimer
        interval: 400
        onTriggered: {
            const dev = root.pairingDevice;
            if (!dev) return;
            root.pairingDevice = null;
            if (dev.paired) {
                if (!dev.connected) dev.connect();
            } else {
                root.error = "Pairing failed. Put the device in pairing mode and try again.";
            }
        }
    }

    Connections {
        target: root.pairingDevice
        ignoreUnknownSignals: true
        function onPairedChanged() {
            const dev = root.pairingDevice;
            if (!dev || !dev.paired) return;
            root.pairingDevice = null;
            if (!dev.connected) dev.connect();
        }
        function onPairingChanged() {
            if (root.pairingDevice && !root.pairingDevice.pairing)
                pairSettleTimer.restart();
        }
    }

    Connections {
        target: root.adapter
        ignoreUnknownSignals: true
        function onStateChanged() {
            if (root.adapter?.state === BluetoothAdapterState.Blocked)
                root.error = "Bluetooth is blocked by rfkill. Run: rfkill unblock bluetooth";
        }
    }
}
