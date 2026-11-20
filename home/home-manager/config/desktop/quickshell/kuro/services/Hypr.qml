pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Hyprland display options.
//
// Changes are applied immediately via `hyprctl eval` (so the desktop reacts
// right away) and written back to ~/.config/kuro/kuro.toml, which is the
// single source of truth. kurogen then regenerates kuro.lua, kitty.conf and
// the shell theme.
Singleton {
    id: root

    property bool ready: false
    property int gapsIn: 0
    property int gapsOut: 0
    property int borderSize: 0
    property int rounding: 0
    property bool blur: false
    property bool animations: true

    // Runtime (hyprctl) option names.
    readonly property var options: ({
        gapsIn: "general:gaps_in",
        gapsOut: "general:gaps_out",
        borderSize: "general:border_size",
        rounding: "decoration:rounding",
        blur: "decoration:blur:enabled",
        animations: "animations:enabled"
    })

    // Matching keys in kuro.toml.
    readonly property var toml: ({
        gapsIn: "theme.gaps_in",
        gapsOut: "theme.gaps_out",
        borderSize: "theme.border_size",
        rounding: "theme.rounding",
        blur: "theme.blur",
        animations: "theme.animations"
    })

    property var pending: ({})

    function refresh() {
        if (!readProc.running) readProc.running = true;
    }

    // JS value -> Lua literal
    function luaValue(value) {
        if (typeof value === "boolean") return value ? "true" : "false";
        return String(value);
    }

    // "decoration:blur:enabled", true -> hl.config({ decoration = { blur = { enabled = true } } })
    function luaSet(path, value) {
        const parts = path.split(":");
        let s = luaValue(value);
        for (let i = parts.length - 1; i >= 0; i--)
            s = "{ " + parts[i] + " = " + s + " }";
        return "hl.config(" + s + ")";
    }

    function set(key, value) {
        root[key] = value;
        Quickshell.execDetached(["hyprctl", "eval", luaSet(options[key], value)]);

        // Persist in kuro.toml; the timer batches multi-key changes.
        const p = Object.assign({}, pending);
        p[key] = value;
        pending = p;
        saveTimer.restart();
    }

    function readValue(j) {
        if (j.bool !== undefined) return j.bool ? 1 : 0;
        if (j.int !== undefined) return j.int;
        if (j.float !== undefined) return Math.round(j.float);
        return parseInt(String(j.custom ?? "0").trim().split(/\s+/)[0]) || 0;
    }

    Process {
        id: readProc
        command: ["sh", "-c",
            "for o in general:gaps_in general:gaps_out general:border_size decoration:rounding " +
            "decoration:blur:enabled animations:enabled; do " +
            "echo \"$(hyprctl -j getoption \"$o\" 2>/dev/null | tr -d '\\n')\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                const keys = ["gapsIn", "gapsOut", "borderSize", "rounding", "blur", "animations"];
                let ok = 0;
                keys.forEach((k, i) => {
                    try {
                        const v = root.readValue(JSON.parse(l[i]));
                        root[k] = (k === "blur" || k === "animations") ? v !== 0 : v;
                        ok++;
                    } catch (e) {}
                });
                root.ready = ok > 0;
            }
        }
    }

    // Write the batched changes to kuro.toml 150 ms after the last change.
    Timer {
        id: saveTimer
        interval: 150
        onTriggered: {
            const parts = [Config.kurogen, "set"];
            for (const key in root.pending) {
                parts.push(root.toml[key]);
                parts.push(root.luaValue(root.pending[key]));
            }
            root.pending = ({});
            if (parts.length > 2) {
                writeProc.command = parts;
                writeProc.running = true;
            }
        }
    }

    Process { id: writeProc }
}
