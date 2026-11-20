pragma Singleton

import QtQuick
import Quickshell

// State for the compact click popups opened from bar modules.
Singleton {
    id: root

    property bool open: false
    property bool closing: false
    property string kind: ""
    property var target: null
    property var barWindow: null

    function show(kind, target, barWindow) {
        closeTimer.stop();
        root.closing = false;
        root.kind = kind;
        root.target = target;
        root.barWindow = barWindow;
        root.open = true;
    }

    function toggle(kind, target, barWindow) {
        if (root.open && root.kind === kind) {
            root.close();
            return;
        }
        root.show(kind, target, barWindow);
    }

    function close() {
        if (!root.open && root.closing) return;
        root.open = false;
        root.closing = true;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 210
        onTriggered: {
            root.closing = false;
            root.kind = "";
            root.target = null;
            root.barWindow = null;
        }
    }
}
