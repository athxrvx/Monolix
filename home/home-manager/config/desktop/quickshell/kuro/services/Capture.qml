pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Desktop screenshot, color picker and recording actions.
Singleton {
    id: root

    property bool recording: false
    property string screenshotError: ""
    signal screenshotFinished(bool success, string detail)

    function screenshot(area, geometry, frozenFrame) {
        if (screenshotProc.running) return;
        screenshotError = "";
        screenshotProc.errorText = "";
        screenshotProc.command = [Config.captureScript, "screenshot", area,
            geometry ?? "", frozenFrame ?? ""];
        screenshotProc.running = true;
    }

    function pickColor() {
        Quickshell.execDetached(["hyprpicker", "-a"]);
    }

    function startRecording(area, audio, geometry) {
        if (recording) return;
        recording = true;
        Quickshell.execDetached([Config.captureScript, "record", area, audio, geometry ?? ""]);
    }

    Process {
        id: screenshotProc
        property string errorText: ""
        stderr: StdioCollector { onStreamFinished: screenshotProc.errorText = text.trim() }
        onExited: (code, status) => {
            root.screenshotError = code === 0 ? "" : (errorText || "Screenshot command failed with exit code " + code + ".");
            root.screenshotFinished(code === 0, root.screenshotError);
        }
    }

    function stopRecording() {
        if (!recording) return;
        Quickshell.execDetached([Config.captureScript, "stop"]);
        recording = false;
    }

    FileView {
        path: Config.captureStateFile
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.recording = text().trim() !== ""
        onLoadFailed: root.recording = false
    }
}
