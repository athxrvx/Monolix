pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Bar state: visibility and the three supported bar layouts.
//
// Adding a layout means adding one entry to `layouts`:
//   style  : "solid" one solid bar, "islands" separate left/center/right surfaces
//   height, radius (kept at 0 for sharp corners), margin { top, left, right }
//   island : true = center is replaced by the dynamic island (island/Island.qml), `center` ignored
//   left / center / right : module lists, see bar/Module.qml
//     workspaces[:kanji|:roman] clock date datetime network bluetooth
//     volume mic brightness battery cpu memory tray notification profile clipboard overview weather mouse ai
Singleton {
    id: root

    property bool shown: Config.barEnabled
    property string current: Config.barLayout

    readonly property var layouts: ({
        "full": {
            style: "solid", height: 30, radius: 0, margin: { top: 0, left: 0, right: 0 },
            left:   ["workspaces"],
            center: ["clock"],
            right:  ["tray", "ai", "network", "bluetooth", "volume", "mouse", "battery", "notification"]
        },
        "float": {
            style: "solid", height: 32, radius: 0, margin: { top: 8, left: 12, right: 12 },
            left:   ["workspaces"],
            center: ["clock"],
            right:  ["tray", "ai", "network", "bluetooth", "volume", "mic", "battery", "notification"]
        },
        "island": {
            style: "islands", height: 32, radius: 0, margin: { top: 6, left: 10, right: 10 }, island: true,
            left:   ["workspaces:kanji"],
            center: [],
            right:  ["tray", "ai", "network", "bluetooth", "volume", "battery", "notification"]
        }
    })

    readonly property var names: Object.keys(layouts)
    readonly property var layout: layouts[current] ?? layouts[Config.barLayout] ?? layouts[names[0]]
    readonly property var allModules: layout.left.concat(layout.center, layout.right)

    // Shared clock for all bars
    property alias clock: sysClock
    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    function set(name) {
        if (!layouts[name]) return false;
        current = name;
        saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
                            "sh", name, Config.barStateFile];
        saveProc.running = true;
        return true;
    }

    function next() {
        const i = names.indexOf(current);
        set(names[(i + 1) % names.length]);
    }

    // Restore the last layout at startup
    FileView {
        path: Config.barStateFile
        printErrors: false
        onLoaded: {
            const n = text().trim();
            if (root.layouts[n]) root.current = n;
        }
    }

    Process { id: saveProc }
}
