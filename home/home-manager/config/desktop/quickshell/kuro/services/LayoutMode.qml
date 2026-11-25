pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    readonly property var modes: ["dwindle", "scrolling"]
    property string current: "dwindle"
    property string pendingMode: ""

    function refresh() {
        if (!readProc.running) readProc.running = true;
    }

    function cycle() {
        if (!cycleProc.running) cycleProc.running = true;
    }

    function set(mode) {
        if (modes.indexOf(mode) === -1 || persistProc.running || setProc.running) return;
        pendingMode = mode;
        persistProc.command = [Config.kurogen, "set", "hypr.layout", mode];
        persistProc.running = true;
    }

    readonly property string setLua: [
            'local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()',
            'if workspace then',
            '  local selector = workspace.special and tostring(workspace.name) or "name:" .. tostring(workspace.name)',
            '  local animation = "' + pendingMode + '" == "scrolling" and "slidevert" or "slide"',
            '  hl.workspace_rule({ workspace = selector, layout = "' + pendingMode + '", animation = animation })',
            '  if kuroSyncWorkspaceGestures then kuroSyncWorkspaceGestures(workspace, "' + pendingMode + '") end',
            'end'
        ].join("; ")

    readonly property string cycleLua: [
        'local layouts = {"dwindle", "scrolling"}',
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
        '    hl.workspace_rule({ workspace = tostring(workspace.name), layout = next_layout, animation = next_layout == "scrolling" and "slidevert" or "slide" })',
        '  else',
        '    hl.workspace_rule({ workspace = "name:" .. tostring(workspace.name), layout = next_layout, animation = next_layout == "scrolling" and "slidevert" or "slide" })',
        '  end',
        '  if kuroSyncWorkspaceGestures then kuroSyncWorkspaceGestures(workspace, next_layout) end',
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

    Process {
        id: setProc
        onExited: code => {
            if (code === 0) root.current = root.pendingMode;
            settle.restart();
        }
    }

    Process {
        id: persistProc
        onExited: code => {
            if (code === 0) {
                setProc.command = ["hyprctl", "eval", root.setLua];
                setProc.running = true;
            }
        }
    }

    Timer {
        id: settle
        interval: 150
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
