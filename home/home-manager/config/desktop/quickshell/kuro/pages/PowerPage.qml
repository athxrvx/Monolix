// Power: battery, power profile (powerprofilesctl), session actions.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    id: root

    signal actionTriggered()

    onPoll: {
        Battery.refresh();
        PowerProfile.refresh();
        GpuStatus.refresh();
        SystemInfo.refresh();
    }

    PageHeader { kicker: "04 · system"; title: "Power" }

    // ── Battery ───────────────────────────────────────────────────
    SectionLabel { visible: Battery.available; text: "battery" }

    RowLayout {
        visible: Battery.available
        Layout.fillWidth: true
        spacing: 24

        StatBlock {
            label: Battery.charging ? "charging" : "level"
            value: Battery.percent
            unit: "%"
            sub: Battery.status.toLowerCase()
        }
        StatBlock {
            visible: Battery.watts > 0
            label: "draw"
            value: Battery.watts.toFixed(1)
            unit: "W"
            sub: Battery.charging ? "in" : "out"
        }
        StatBlock {
            visible: Battery.timeLeft !== ""
            label: Battery.charging ? "until full" : "remaining"
            value: Battery.timeLeft
            sub: "upower"
        }
        Item { Layout.fillWidth: true }
    }

    // Battery level bar
    Rectangle {
        visible: Battery.available
        Layout.fillWidth: true
        implicitHeight: 4
        radius: 2
        color: Theme.surface2

        Rectangle {
            width: parent.width * Battery.percent / 100
            height: parent.height
            radius: 2
            color: Battery.percent <= 15 && !Battery.charging ? Theme.danger : Theme.accent
        }
    }

    SettingRow {
        visible: Battery.available
        Layout.topMargin: 6
        title: "Automatic battery saver"
        sub: PowerAutomation.active
            ? "Active below 30% · power saver · dims to 50% (manual changes are kept)"
            : PowerAutomation.enabled
                ? "At 30% while unplugged · restores on charge or at 35%"
                : "Off · manage the power profile and brightness yourself"
        Switch {
            checked: PowerAutomation.enabled
            onToggled: PowerAutomation.setEnabled(!PowerAutomation.enabled)
        }
    }

    InfoRow {
        visible: MouseBattery.available
        key: "mouse"
        value: MouseBattery.level + "%" + (MouseBattery.charging ? "  ·  charging" : "")
               + (MouseBattery.asleep ? "  ·  asleep" : "")
    }

    // ── Power profile ─────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "power profile" }

    ListRow {
        radius: 0
        icon: Icons.cpu
        title: GpuStatus.running ? "GPU running"
            : GpuStatus.available ? "GPU idle" : "GPU status unavailable"
        sub: GpuStatus.summary
        trailing: GpuStatus.available ? GpuStatus.utilization + "%"
            : Capture.recording ? "recording" : ""
        active: GpuStatus.running
        interactive: false
    }

    Hint {
        visible: !PowerProfile.available
        text: "Power profiles are unavailable. Check that power-profiles-daemon or tuned-ppd is running."
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: PowerProfile.available

        Repeater {
            model: PowerProfile.profiles
            ListRow {
                required property string modelData
                icon: modelData === "performance" ? Icons.speed
                    : modelData === "power-saver" ? Icons.leaf : Icons.balance
                title: PowerProfile.pretty(modelData)
                trailing: PowerProfile.current === modelData ? "active" : ""
                active: PowerProfile.current === modelData
                busy: PowerProfile.applying
                onClicked: PowerProfile.set(modelData)
            }
        }
    }

    Hint {
        visible: PowerProfile.error !== ""
        text: PowerProfile.error
    }

    // ── Session ──────────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "session" }

    PowerMenu {
        id: menu
        onActionTriggered: root.actionTriggered()
    }

    // Confirmation is cancelled when switching pages or closing the window (Esc)
    onActiveChanged: if (!active) menu.cancel()

    InfoRow { key: "host";   value: SystemInfo.user + "@" + SystemInfo.host }
    InfoRow { key: "uptime"; value: SystemInfo.uptime }
}
