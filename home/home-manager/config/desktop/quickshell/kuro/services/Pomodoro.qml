pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int duration: 25 * 60
    property int remainingSeconds: duration
    property bool running: false

    readonly property string remainingText: {
        const minutes = Math.floor(remainingSeconds / 60).toString().padStart(2, "0");
        const seconds = (remainingSeconds % 60).toString().padStart(2, "0");
        return minutes + ":" + seconds;
    }

    function toggle() {
        if (running) {
            running = false;
            return;
        }
        if (remainingSeconds <= 0) remainingSeconds = duration;
        running = true;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.remainingSeconds <= 1) {
                root.remainingSeconds = 0;
                root.running = false;
                Quickshell.execDetached(["notify-send", "-a", "Kuro", "Pomodoro complete",
                    "Your 25-minute focus session is done."]);
            } else {
                root.remainingSeconds--;
            }
        }
    }
}
