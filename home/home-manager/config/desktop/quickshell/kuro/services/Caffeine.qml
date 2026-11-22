pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool active: inhibitor.running

    function toggle() {
        inhibitor.running = !inhibitor.running;
    }

    Process {
        id: inhibitor
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=Kuro",
            "--why=Caffeine mode", "--mode=block", "sleep", "infinity"]
    }
}
