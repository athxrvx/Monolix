// Wallpaper for external screens, drawn by Quickshell itself.
// awww-daemon sometimes never picks up a hotplugged output (e.g. a VGA TV), leaving it black.
// awww keeps handling the laptop panel; every other screen gets the same image here.
// The path comes from ~/.cache/wal/wal, which pywal rewrites on every wallpaper change.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services

Scope {
    id: root

    signal showWallpaperPicker()
    signal showThemePicker()

    // pywal's record of the current wallpaper, falling back to what awww reports
    property string walImage: ""
    readonly property string image: walImage !== "" ? walImage : Wallpaper.current

    FileView {
        path: Config.home + "/.cache/wal/wal"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.walImage = text().trim()
    }

    Component.onCompleted: Wallpaper.refresh()

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: true
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell-backdrop"
            // Keep the background layer transparent when the wallpaper is
            // supplied by awww on this output. An opaque fill here hides it.
            color: "transparent"

            Image {
                id: current
                anchors.fill: parent
                visible: Config.backdropExternal && !/^(eDP|LVDS|DSI)/.test(modelData.name)
                source: root.image !== "" ? "file://" + root.image : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize.width: parent.width
                sourceSize.height: parent.height
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 500 } }
            }

            // Use unused desktop space as a small shortcut surface, in the
            // same spirit as Omarchy: double-left opens wallpaper selection;
            // double-right opens the theme picker.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onDoubleClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) root.showWallpaperPicker();
                    else if (mouse.button === Qt.RightButton) root.showThemePicker();
                }
            }
        }
    }
}
