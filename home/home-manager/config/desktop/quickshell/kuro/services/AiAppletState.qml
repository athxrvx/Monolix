pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var target: null
    signal openRequested(var appletItem, var panelWindow)
    signal toggleRequested(var appletItem, var panelWindow)
    property var barWindow: null

    function register(item, window) {
        target = item;
        barWindow = window;
    }

    function unregister(item) {
        if (target === item) {
            target = null;
            barWindow = null;
        }
    }

    function open() {
        if (target && barWindow) openRequested(target, barWindow);
    }

    function toggle() {
        if (target && barWindow) toggleRequested(target, barWindow);
    }
}
