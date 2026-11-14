//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma IconTheme Papirus-Dark

import "modules"
import "components"
import "modules/drawers"
import "modules/areapicker"
import "modules/lock"
import "modules/quicktoggles"
import "modules/webapps"
import "modules/music"
import "modules/hub"
import "modules/background"
import "modules/polkit"
import qs.modules.controlcenter
import qs.services
import qs.config

import Quickshell
import Quickshell.Io
import QtQml

ShellRoot {
    id: root

    function applyDesktopThemes(): void {
        gtkThemeProcess.command = ["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", Config.appearance.gtkTheme ?? "adw-gtk3"];
        gtkThemeProcess.running = true;
        iconThemeProcess.command = ["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", Config.appearance.iconTheme ?? "Papirus-Dark"];
        iconThemeProcess.running = true;
    }

    Component.onCompleted: {
        if (Config.initialLoadComplete)
            Qt.callLater(root.applyDesktopThemes);
    }

    Connections {
        target: Config

        function onConfigLoaded(elapsed: int): void {
            Qt.callLater(root.applyDesktopThemes);
        }
    }

    Process {
        id: gtkThemeProcess
        command: ["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", "adw-gtk3"]
        running: false
    }

    Process {
        id: iconThemeProcess
        command: ["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", "Papirus-Dark"]
        running: false
    }

    Backdrop {}
    Background {}
    Drawers {}
    AreaPicker {}
    Lock {}

    Shortcuts {}
    WebAppCreator {}
    QuickTogglesPanel {}

    // Native polkit authentication agent — replaces polkit-kde-authentication-agent-1
    PolkitDialog {}

    ReloadPopup {}

    // Initialize BatteryMonitor service
    property var _batteryMonitor: BatteryMonitor
}
