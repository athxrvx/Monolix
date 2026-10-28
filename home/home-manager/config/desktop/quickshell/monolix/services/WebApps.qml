pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

Singleton {
    id: root

    property var apps: []
    property bool busy: false
    property string _action: ""
    property string _stdout: ""
    property string _stderr: ""
    property string previewSource: ""
    property string previewName: ""
    property string _previewUrl: ""
    property string _previewNameRequest: ""
    property string _activePreviewUrl: ""
    property string _activePreviewName: ""
    property string _previewStdout: ""

    signal operationFinished(string action, bool success, string message)

    function create(name: string, url: string, icon: string): void {
        run("create", [name, url, icon]);
    }

    function update(id: string, name: string, url: string, icon: string): void {
        run("update", [id, name, url, icon]);
    }

    function remove(id: string): void {
        run("delete", [id]);
    }

    function requestIconPreview(url: string, name: string): void {
        _previewUrl = url;
        _previewNameRequest = name;
        previewSource = "";
        previewName = name;
        if (!previewProcess.running)
            startIconPreview();
    }

    function clearIconPreview(): void {
        _previewUrl = "";
        _previewNameRequest = "";
        previewSource = "";
        previewName = "";
    }

    function startIconPreview(): void {
        if (!_previewUrl || !_previewNameRequest || previewProcess.running)
            return;
        _activePreviewUrl = _previewUrl;
        _activePreviewName = _previewNameRequest;
        _previewStdout = "";
        previewProcess.command = ["python3", `${Quickshell.shellDir}/utils/scripts/webapps.py`, "preview", _activePreviewName, _activePreviewUrl];
        previewProcess.running = true;
    }

    function launch(id: string): void {
        const app = apps.find(item => item.id === id);
        if (!app)
            return;
        Quickshell.execDetached([
            "systemd-run", "--user", "--scope", "--collect", "--quiet", "--",
            "chromium", `--app=${app.url}`
        ]);
    }

    function run(action: string, args: list<string>): void {
        if (busy)
            return;
        busy = true;
        _action = action;
        _stdout = "";
        _stderr = "";
        helperProcess.command = ["python3", `${Quickshell.shellDir}/utils/scripts/webapps.py`, action, ...args];
        helperProcess.running = true;
    }

    FileView {
        id: registry
        path: `${Paths.data}/webapps.json`
        watchChanges: true

        onLoaded: {
            try {
                const value = JSON.parse(text());
                root.apps = Array.isArray(value) ? value : [];
            } catch (error) {
                console.error("Web apps: could not read registry:", error);
                root.apps = [];
            }
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                root.apps = [];
            else
                console.error("Web apps: registry read failed:", FileViewError[error] || error);
        }
    }

    Process {
        id: previewProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._previewStdout = this.text
        }
        onExited: (exitCode, exitStatus) => {
            if (root._activePreviewUrl === root._previewUrl && root._activePreviewName === root._previewNameRequest && exitCode === 0) {
                try {
                    const preview = JSON.parse(root._previewStdout.trim());
                    root.previewSource = preview.source || "";
                    root.previewName = preview.name || root._activePreviewName;
                } catch (error) {
                    console.warn("Web apps: could not read icon preview:", error);
                }
            }
            if (root._previewUrl && (root._activePreviewUrl !== root._previewUrl || root._activePreviewName !== root._previewNameRequest))
                root.startIconPreview();
        }
    }

    Process {
        id: helperProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._stdout = this.text
        }
        stderr: StdioCollector {
            onStreamFinished: root._stderr = this.text
        }
        onExited: (exitCode, exitStatus) => {
            root.busy = false;
            if (exitCode === 0) {
                registry.reload();
                root.operationFinished(root._action, true, root._stdout.trim() || "Web app saved");
            } else {
                root.operationFinished(root._action, false, root._stderr.trim() || "Could not save the web app");
            }
        }
    }
}
