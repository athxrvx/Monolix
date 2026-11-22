pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// One-shot battery saver: dim at 30% while discharging, then let the user
// adjust brightness freely. Restore the previous settings on AC or at 35%.
Singleton {
    id: root

    property bool enabled: true
    property bool active: false
    property bool loaded: false
    property string previousProfile: ""
    property bool profileHandled: false
    property bool profileChanged: false
    property real previousBrightness: -1
    property bool brightnessHandled: false
    property bool brightnessChanged: false
    property bool brightnessOverridden: false
    property int brightnessRevision: 0

    readonly property int threshold: 30
    readonly property int resumeThreshold: 35
    readonly property real targetBrightness: 0.5

    function save() {
        if (!loaded) return;
        saveProc.command = ["sh", "-c",
            'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
            "sh", JSON.stringify({
                enabled: enabled,
                active: active,
                previousProfile: previousProfile,
                profileHandled: profileHandled,
                profileChanged: profileChanged,
                previousBrightness: previousBrightness,
                brightnessHandled: brightnessHandled,
                brightnessChanged: brightnessChanged,
                brightnessOverridden: brightnessOverridden,
                brightnessRevision: brightnessRevision
            }), Config.powerAutomationStateFile];
        saveProc.running = true;
    }

    function begin() {
        active = true;
        previousProfile = "";
        profileHandled = false;
        profileChanged = false;
        previousBrightness = -1;
        brightnessHandled = false;
        brightnessChanged = false;
        brightnessOverridden = false;
        brightnessRevision = Brightness.userRevision;
        save();
        apply();
    }

    function apply() {
        if (!active) return;

        if (!profileHandled && PowerProfile.available) {
            previousProfile = PowerProfile.current;
            profileHandled = true;
            if (PowerProfile.current !== "power-saver" && PowerProfile.profiles.indexOf("power-saver") !== -1) {
                profileChanged = true;
                PowerProfile.set("power-saver");
            }
            save();
        }

        if (!brightnessHandled && Brightness.available) {
            previousBrightness = Brightness.value;
            brightnessHandled = true;
            brightnessRevision = Brightness.userRevision;
            if (Brightness.value > targetBrightness) {
                brightnessChanged = true;
                Brightness.setValueAutomatic(targetBrightness);
            }
            save();
        }
    }

    function end() {
        if (profileChanged && PowerProfile.current === "power-saver" &&
            previousProfile !== "" && previousProfile !== "power-saver") {
            PowerProfile.set(previousProfile);
        }
        if (brightnessChanged && !brightnessOverridden &&
            Brightness.userRevision === brightnessRevision &&
            Math.abs(Brightness.value - targetBrightness) < 0.025 && previousBrightness >= 0) {
            Brightness.setValueAutomatic(previousBrightness);
        }

        active = false;
        previousProfile = "";
        profileHandled = false;
        profileChanged = false;
        previousBrightness = -1;
        brightnessHandled = false;
        brightnessChanged = false;
        brightnessOverridden = false;
        save();
    }

    function evaluate() {
        if (!loaded || !Battery.available) return;
        const discharging = Battery.status === "Discharging";
        if (active && (!enabled || !discharging || Battery.percent >= resumeThreshold)) {
            end();
            return;
        }
        if (!active && enabled && discharging && Battery.percent <= threshold) begin();
        else apply();
    }

    function setEnabled(value) {
        if (enabled === value) return;
        enabled = value;
        if (!enabled && active) end();
        else if (enabled) evaluate();
        save();
    }

    Connections {
        target: Battery
        function onAvailableChanged() { root.evaluate(); }
        function onPercentChanged() { root.evaluate(); }
        function onStatusChanged() { root.evaluate(); }
    }

    Connections {
        target: PowerProfile
        function onAvailableChanged() { root.apply(); }
        function onCurrentChanged() { root.evaluate(); }
    }

    Connections {
        target: Brightness
        function onAvailableChanged() { root.apply(); }
        function onUserRevisionChanged() {
            if (root.active && root.brightnessChanged) {
                root.brightnessOverridden = true;
                root.save();
            }
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: root.loaded
        triggeredOnStart: true
        onTriggered: {
            Battery.refresh();
            PowerProfile.refresh();
            Brightness.refresh();
            root.evaluate();
            if (root.active && root.brightnessChanged &&
                Math.abs(Brightness.value - root.targetBrightness) >= 0.025) {
                root.brightnessOverridden = true;
                root.save();
            }
        }
    }

    Process { id: saveProc }

    FileView {
        path: Config.powerAutomationStateFile
        printErrors: false
        onLoaded: {
            try {
                const state = JSON.parse(text());
                root.enabled = state.enabled ?? true;
                root.active = state.active ?? false;
                root.previousProfile = state.previousProfile ?? "";
                root.profileHandled = state.profileHandled ?? false;
                root.profileChanged = state.profileChanged ?? false;
                root.previousBrightness = state.previousBrightness ?? -1;
                root.brightnessHandled = state.brightnessHandled ?? false;
                root.brightnessChanged = state.brightnessChanged ?? false;
                root.brightnessOverridden = state.brightnessOverridden ?? false;
                root.brightnessRevision = state.brightnessRevision ?? 0;
            } catch (error) { }
            root.loaded = true;
            Qt.callLater(() => root.evaluate());
        }
        onLoadFailed: {
            root.loaded = true;
            Qt.callLater(() => root.evaluate());
        }
    }
}
