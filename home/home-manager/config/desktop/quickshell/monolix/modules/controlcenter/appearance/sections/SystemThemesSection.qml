pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

CollapsibleSection {
    id: root

    title: qsTr("GTK & icons")
    description: qsTr("Choose the theme used by GTK apps")
    showBackground: true

    property string selectedGtkTheme: Config.appearance.gtkTheme ?? "adw-gtk3"
    property string selectedIconTheme: Config.appearance.iconTheme ?? "Papirus-Dark"

    function applySetting(key: string, value: string): void {
        settingsProcess.command = ["gsettings", "set", "org.gnome.desktop.interface", key, value];
        settingsProcess.running = true;
    }

    function selectGtkTheme(theme: string): void {
        selectedGtkTheme = theme;
        Config.appearance.gtkTheme = theme;
        Config.markDirty("appearance");
        applySetting("gtk-theme", theme);
    }

    function selectIconTheme(theme: string): void {
        selectedIconTheme = theme;
        Config.appearance.iconTheme = theme;
        Config.markDirty("appearance");
        applySetting("icon-theme", theme);
    }

    Process {
        id: settingsProcess
        command: ["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", root.selectedGtkTheme]
        running: false

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Could not apply GTK appearance setting; gsettings exited with code", exitCode);
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.md

        StyledText {
            text: qsTr("GTK theme")
            font.pointSize: Appearance.font.size.bodyMedium
            font.weight: 500
        }

        Repeater {
            model: ["adw-gtk3", "adw-gtk3-dark"]

            delegate: StyledRect {
                required property string modelData
                Layout.fillWidth: true
                implicitHeight: choiceRow.implicitHeight + Appearance.padding.md * 2
                radius: Appearance.rounding.normal
                color: root.selectedGtkTheme === modelData ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainer

                StateLayer {
                    function onClicked(): void {
                        root.selectGtkTheme(modelData);
                    }
                }

                RowLayout {
                    id: choiceRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.md
                    spacing: Appearance.spacing.md

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData === "adw-gtk3-dark" ? qsTr("Adw GTK 3 · Dark") : qsTr("Adw GTK 3")
                        color: root.selectedGtkTheme === modelData ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    }

                    MaterialIcon {
                        visible: root.selectedGtkTheme === modelData
                        text: "check"
                        color: Colours.palette.m3onSecondaryContainer
                    }
                }
            }
        }

        StyledText {
            Layout.topMargin: Appearance.spacing.sm
            text: qsTr("Icon theme")
            font.pointSize: Appearance.font.size.bodyMedium
            font.weight: 500
        }

        Repeater {
            model: ["Papirus-Dark", "Papirus", "Papirus-Light", "Adwaita"]

            delegate: StyledRect {
                required property string modelData
                Layout.fillWidth: true
                implicitHeight: iconRow.implicitHeight + Appearance.padding.md * 2
                radius: Appearance.rounding.normal
                color: root.selectedIconTheme === modelData ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainer

                StateLayer {
                    function onClicked(): void {
                        root.selectIconTheme(modelData);
                    }
                }

                RowLayout {
                    id: iconRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.md
                    spacing: Appearance.spacing.md

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData
                        color: root.selectedIconTheme === modelData ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    }

                    MaterialIcon {
                        visible: root.selectedIconTheme === modelData
                        text: "check"
                        color: Colours.palette.m3onSecondaryContainer
                    }
                }
            }
        }
    }
}
