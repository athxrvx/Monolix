pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Owns the kuro.toml -> generated configs pipeline.
//
// kurogen renders the shell, Hyprland, kitty and Helix themes from kuro.toml.
// This service regenerates them when the TOML changes, then reloads the live
// desktop components.
Singleton {
    id: root

    property bool ready: false
    property bool busy: false
    property bool pendingReload: false
    property bool rerunRequested: false
    property bool schemeBusy: false
    property string pendingScheme: ""

    // Force a regeneration (used by the launcher's "Apply" action).
    function apply() { runGen(true); }

    function runGen(reload) {
        pendingReload = pendingReload || reload;
        if (gen.running) {
            // A file can change while kurogen is reading it. Run once more
            // after the current process so generated files cannot lag behind.
            rerunRequested = true;
            return;
        }
        busy = true;
        gen.running = true;
    }

    // Switch the active colorscheme: kurogen edits kuro.toml, and the
    // FileView below notices the change and regenerates everything.
    function setScheme(name) {
        pendingScheme = name;
        if (schemeBusy) return;
        schemeBusy = true;
        startScheme();
    }

    function startScheme() {
        if (pendingScheme === "") { schemeBusy = false; return; }
        const name = pendingScheme;
        pendingScheme = "";
        schemeProc.command = [Config.kurogen, "set", "theme.scheme", name];
        schemeProc.running = true;
    }

    function reloadApps() { reloadProc.running = true; }

    Process {
        id: gen
        command: [Config.kurogen]
        onExited: code => {
            root.ready = code === 0;
            if (root.rerunRequested) {
                root.rerunRequested = false;
                gen.running = true;
                return;
            }
            root.busy = false;
            if (code === 0 && root.pendingReload) reloadProc.running = true;
            root.pendingReload = false;
        }
    }

    Process {
        id: schemeProc
        onExited: code => {
            if (code !== 0) root.ready = false;
            if (root.pendingScheme !== "") root.startScheme();
            else root.schemeBusy = false;
        }
    }

    Process {
        id: reloadProc
        command: ["sh", "-c",
            "hyprctl reload >/dev/null 2>&1; pkill -USR1 -x kitty >/dev/null 2>&1; true"]
    }

    FileView {
        path: Config.kuroConfig
        watchChanges: true
        printErrors: false
        onFileChanged: root.runGen(true)
    }

    // Keep generated configs in sync at login (in case kuro.toml changed
    // while the shell was not running).
    Component.onCompleted: root.runGen(true)
}
