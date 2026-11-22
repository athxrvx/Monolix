// A single bar module, selected by name from the layout ("clock", "workspaces:kanji", ...).
// Adding a module means adding a Component below and registering it in `comps`.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.overview

Item {
    id: root

    required property string spec
    required property var monitor
    required property var window
    required property var layout

    signal openPage(string name)
    signal toggleControl()

    readonly property string kind: spec.split(":")[0]
    readonly property string arg: spec.split(":")[1] ?? ""
    readonly property bool bordered: layout.style === "border"

    readonly property var comps: ({
        workspaces: workspacesC, window: windowC,
        clock: clockC, date: dateC, datetime: datetimeC,
        network: networkC, bluetooth: bluetoothC,
        volume: volumeC, mic: micC, brightness: brightnessC, battery: batteryC,
        cpu: cpuC, memory: memoryC, profile: profileC,
        notification: notificationC, tray: trayC, clipboard: clipboardC, overview: overviewC,
        mouse: mouseC, ai: aiC
    })

    // Hide modules whose data is unavailable (for example battery on a desktop)
    visible: ({
        mouse: MouseBattery.available,
        bluetooth: Bluetooth.available,
        mic: Audio.hasMic,
        brightness: Brightness.available,
        battery: Battery.available,
        profile: PowerProfile.available
    })[kind] ?? true
    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    Rectangle {
        id: frame
        anchors.fill: parent
        implicitWidth: loader.implicitWidth + (root.bordered ? 12 : 0)
        implicitHeight: root.layout.height - (root.bordered ? 12 : 6)
        color: "transparent"
        radius: root.layout.radius
        border.width: root.bordered ? 1 : 0
        border.color: Theme.border

        Loader {
            id: loader
            anchors.centerIn: parent
            width: implicitWidth
            height: implicitHeight
            sourceComponent: root.comps[root.kind] ?? unknownC
        }
    }

    // ── Components ───────────────────────────────────────────────────

    Component {
        id: workspacesC
        Workspaces {
            monitor: root.monitor
            numerals: root.arg
            itemHeight: root.layout.height - 10
        }
    }

    Component {
        id: windowC
        Text {
            id: windowLabel
            width: Math.min(implicitWidth, 320)
            // "window" shows the title, "window:app" only the app name
            text: {
                const t = ToplevelManager.activeToplevel;
                if (!t) return "";
                if (root.arg !== "app") return t.title;
                // "org.mozilla.firefox" -> "Firefox", "kitty" -> "Kitty"
                const id = (t.appId || "").split(".").pop();
                return id.charAt(0).toUpperCase() + id.slice(1);
            }
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            elide: Text.ElideRight

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: BarPopup.toggle("window", windowLabel, root.window)
            }
        }
    }

    // Clock: clicking the clock opens the calendar popup
    Component {
        id: clockC
        ClockItem {
            id: clockItem
            barWindow: root.window
            format: "dd MMM hh:mm"
            labelColor: Theme.text
            onClicked: clockItem.toggleCalendar()
        }
    }
    Component {
        id: dateC
        ClockItem {
            id: dateItem
            barWindow: root.window
            format: "ddd dd MMM"
            onClicked: dateItem.toggleCalendar()
        }
    }
    Component {
        id: datetimeC
        ClockItem {
            id: datetimeItem
            barWindow: root.window
            format: "ddd dd MMM   hh:mm"
            labelColor: Theme.text
            onClicked: datetimeItem.toggleCalendar()
        }
    }

    // Mouse battery: click opens a popup, dimmed while the mouse sleeps
    Component {
        id: mouseC
        BarItem {
            id: mouseItem
            icon: MouseBattery.charging ? Icons.charging : String.fromCodePoint(0xF037D)
            label: MouseBattery.level + "%"
            dimmed: MouseBattery.asleep
            iconColor: MouseBattery.level <= Config.mouseLowBattery && !MouseBattery.charging ? Theme.danger : Theme.text
            onClicked: BarPopup.toggle("mouse", mouseItem, root.window)
        }
    }

    Component {
        id: networkC
        BarItem {
            id: networkItem
            icon: Network.ethConnected ? Icons.ethernet
                : Network.ssid !== "" ? Icons.wifiStrength[Math.min(4, Math.floor(Network.wifiSignal / 20))]
                : Icons.wifiOff
            dimmed: !Network.online
            onClicked: BarPopup.toggle("network", networkItem, root.window)
        }
    }

    Component {
        id: bluetoothC
        BarItem {
            id: bluetoothItem
            icon: !Bluetooth.powered ? Icons.bluetoothOff
                : Bluetooth.device !== "" ? Icons.bluetoothOn : Icons.bluetooth
            dimmed: !Bluetooth.powered
            onClicked: BarPopup.toggle("bluetooth", bluetoothItem, root.window)
        }
    }

    Component {
        id: volumeC
        BarItem {
            id: volumeItem
            icon: Icons.volumeForLevel(Audio.volume, Audio.muted)
            onClicked: BarPopup.toggle("volume", volumeItem, root.window)
            onRightClicked: Audio.toggleMute()
            onScrolled: d => Audio.setVolume(Audio.volume + (d > 0 ? 0.05 : -0.05))
        }
    }

    Component {
        id: micC
        BarItem {
            id: micItem
            visible: Audio.hasMic
            icon: Audio.micMuted ? Icons.micOff : Icons.mic
            dimmed: Audio.micMuted
            onClicked: BarPopup.toggle("mic", micItem, root.window)
            onRightClicked: Audio.toggleMicMute()
            onScrolled: d => Audio.setMicVolume(Audio.micVolume + (d > 0 ? 0.05 : -0.05))
        }
    }

    Component {
        id: brightnessC
        BarItem {
            id: brightnessItem
            visible: Brightness.available
            icon: Icons.brightness
            label: Math.round(Brightness.value * 100) + "%"
            onClicked: BarPopup.toggle("brightness", brightnessItem, root.window)
            onScrolled: d => Brightness.setValue(Brightness.value + (d > 0 ? 0.05 : -0.05))
        }
    }

    Component {
        id: batteryC
        BarItem {
            id: batteryItem
            visible: Battery.available
            icon: Icons.batteryForLevel(Battery.percent, Battery.charging)
            iconColor: Battery.percent <= 10 && !Battery.charging ? Theme.danger : Theme.text
            onClicked: BarPopup.toggle("battery", batteryItem, root.window)
        }
    }

    Component {
        id: cpuC
        BarItem {
            id: cpuItem
            icon: Icons.cpu
            label: Math.round(SystemStats.cpu * 100) + "%"
            iconColor: SystemStats.cpu > 0.8 ? Theme.rose : Theme.text
            onClicked: BarPopup.toggle("memory", cpuItem, root.window)
        }
    }

    Component {
        id: memoryC
        BarItem {
            id: memoryItem
            icon: Icons.memory
            label: Math.round(SystemStats.mem * 100) + "%"
            onClicked: BarPopup.toggle("memory", memoryItem, root.window)
        }
    }

    Component {
        id: profileC
        BarItem {
            id: profileItem
            visible: PowerProfile.available
            icon: PowerProfile.current === "performance" ? Icons.speed
                : PowerProfile.current === "power-saver" ? Icons.leaf : Icons.balance
            // Left click opens profiles; right click opens the launcher's Power page.
            onClicked: BarPopup.toggle("profile", profileItem, root.window)
            onRightClicked: root.openPage("power")
        }
    }

    Component {
        id: notificationC
        BarItem {
            icon: Notifications.dnd ? Icons.bellOff : Icons.bell
            label: Notifications.count > 0 ? String(Notifications.count) : ""
            iconColor: Notifications.count > 0 && !Notifications.dnd ? Theme.rose : Theme.text
            // Left = notification panel under the bar, right = DND, middle = clear all
            onClicked: Notifications.toggleCenter()
            onRightClicked: Notifications.toggle()
            onMiddleClicked: Notifications.clearAll()
        }
    }

    Component {
        id: overviewC
        BarItem {
            icon: Icons.overview
            onClicked: OverviewState.toggle()
        }
    }

    Component {
        id: clipboardC
        BarItem {
            id: clipboardItem
            icon: Icons.clipboard
            onClicked: BarPopup.toggle("clipboard", clipboardItem, root.window)
        }
    }

    Component {
        id: aiC
        BarItem {
            id: aiItem
            icon: Icons.bot
            onClicked: {
                AiAppletState.register(aiItem, root.window);
                BarPopup.toggle("ai", aiItem, root.window);
            }
            Component.onCompleted: AiAppletState.register(aiItem, root.window)
            Component.onDestruction: AiAppletState.unregister(aiItem)
        }
    }

    Component {
        id: trayC
        BarItem {
            id: trayItem
            icon: Icons.tray
            onClicked: BarPopup.toggle("tray", trayItem, root.window)
        }
    }
    Component {
        id: unknownC
        BarText { text: "?" + root.spec; color: Theme.danger }
    }
}
