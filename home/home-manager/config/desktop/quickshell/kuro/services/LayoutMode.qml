pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var modes: ["master", "dwindle", "scrolling"]
    property string current: "dwindle"

    function refresh() {
        if (!readProc.running) readProc.running = true;
    }

    function cycle() {
        if (!cycleProc.running) cycleProc.running = true;
    }

    readonly property string cycleLua: [
        'local layouts = {"master", "dwindle", "scrolling"}',
        'local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()',
        'if workspace then',
        '  local next_layout = layouts[1]',
        '  for i, layout in ipairs(layouts) do',
        '    if layout == workspace.tiled_layout then',
        '      next_layout = layouts[(i % #layouts) + 1]',
        '      break',
        '    end',
        '  end',
        '  if workspace.special then',
        '    hl.workspace_rule({ workspace = tostring(workspace.name), layout = next_layout })',
        '  else',
        '    hl.workspace_rule({ workspace = "name:" .. tostring(workspace.name), layout = next_layout })',
        '  end',
        'end'
    ].join("; ")

    Process {
        id: readProc
        command: ["hyprctl", "repl", "(hl.get_active_special_workspace() or hl.get_active_workspace()).tiled_layout"]
        stdout: StdioCollector {
            onStreamFinished: {
                const mode = text.trim().split(/\s+/).pop();
                if (root.modes.indexOf(mode) !== -1) root.current = mode;
            }
        }
    }

    Process {
        id: cycleProc
        command: ["hyprctl", "eval", root.cycleLua]
        onExited: settle.restart()
    }

    Timer {
        id: settle
        interval: 150
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
