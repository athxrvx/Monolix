// Appearance: palette, bar layout, blur and animation preferences.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services
import qs.bar

Page {
    onOpened: Hypr.refresh()

    PageHeader { kicker: "03 · look"; title: "Appearance" }

    // ── Palette ─────────────────────────────────────────────────────
    SectionLabel { text: "palette" }

    InfoRow {
        key: "source"
        value: Config.usePywal
               ? (Theme.walActive ? "pywal  ·  ~/.cache/wal/colors.json" : "pywal  ·  waiting for colors.json")
               : "built-in palette  ·  config/Theme.qml"
    }

    Flow {
        Layout.fillWidth: true
        spacing: 6
        visible: Theme.palette.length > 0

        Repeater {
            model: Theme.palette
            Rectangle {
                required property string modelData
                width: 26
                height: 26
                radius: Theme.radiusSmall
                color: modelData
                border.color: Theme.border
            }
        }
    }

    Hint {
        text: Config.usePywal
              ? "Window colors follow pywal live. Change the wallpaper on the Wallpaper page to generate a new palette."
              : "Shell uses the built-in 16-color palette. Set Config.usePywal = true to follow pywal instead."
    }

    // ── Bar ──────────────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "bar" }

    SettingRow {
        title: "Show bar"
        sub: "Layout: " + BarState.current
        Switch { checked: BarState.shown; onToggled: BarState.shown = !BarState.shown }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 4
        rowSpacing: 2

        Repeater {
            model: BarState.names

            ListRow {
                required property string modelData
                readonly property var l: BarState.layouts[modelData]
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                title: modelData
                sub: l.style + "  ·  " + l.height + "px" + (l.margin.top > 0 ? "  ·  floating" : "")
                trailing: BarState.current === modelData ? "active" : ""
                active: BarState.current === modelData
                onClicked: BarState.set(modelData)
            }
        }
    }

    Hint { text: "Layouts and modules live in bar/BarState.qml. From a terminal or rofi: bar-layout." }

    SettingRow {
        Layout.topMargin: 4
        title: "Blur"
        sub: "decoration:blur:enabled"
        enabled: Hypr.ready
        Switch { checked: Hypr.blur; onToggled: Hypr.set("blur", !Hypr.blur) }
    }

    SettingRow {
        title: "Animations"
        sub: "animations:enabled"
        enabled: Hypr.ready
        Switch { checked: Hypr.animations; onToggled: Hypr.set("animations", !Hypr.animations) }
    }

    Hint {
        text: "Applied right away and saved to ~/.config/hypr/quickshell.lua. " +
              "Loaded at login by load(\"quickshell\") at the end of hyprland.lua."
    }
}
