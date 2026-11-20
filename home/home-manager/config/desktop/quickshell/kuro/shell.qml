//@ pragma UseQApplication
// Entry point. Run:        quickshell -p ~/.config/quickshell/shell
// Toggle:                  quickshell -p ~/.config/quickshell/shell ipc call controlcenter toggle
// Bar on/off:              quickshell -p ~/.config/quickshell/shell ipc call bar toggle
// Change bar layout:       quickshell -p ~/.config/quickshell/shell ipc call bar layout float

import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar
import qs.notifications
import qs.overview
import qs.services
import qs.island
import qs.launcher
import qs.dock
import qs.desktop
import qs.lock
import qs.capture
import qs.monitor
import qs.sidebar

ShellRoot {
    // Instantiate the kuro.toml watcher/generator for the whole session.
    property bool kuroReady: Kuro.ready

    Popups {}
    NotifCenter {}
    StylePicker { id: stylePicker }
    SystemMonitor { id: systemMonitor }
    SidebarWindow { id: sidebarWindow }

    IpcHandler {
        target: "sidebar"
        function toggle(): void { sidebarWindow.toggle() }
        function open(): void { sidebarWindow.open() }
        function close(): void { sidebarWindow.close() }
        function tab(index: int): void { sidebarWindow.selectTab(index === 1 ? 1 : 0) }
        function animeMenu(prompt: string, inputPath: string, outputPath: string): string {
            return sidebarWindow.requestAnimeMenu(prompt, inputPath, outputPath);
        }
    }

    IpcHandler {
        target: "monitor"
        function open(): void { systemMonitor.openWindow() }
        function toggle(): void { systemMonitor.toggle() }
        function close(): void { systemMonitor.visible = false }
    }

    IpcHandler {
        target: "stylepicker"
        function wallpaper(): void { stylePicker.show("wallpaper") }
        function theme(): void { stylePicker.show("theme") }
    }

    Backdrop {
        onShowWallpaperPicker: stylePicker.show("wallpaper")
        onShowThemePicker: stylePicker.show("theme")
    }

    LockScreen { id: lockScreen }
    CaptureOverlay { id: captureOverlay }

    IpcHandler {
        target: "capture"
        function toggle(): void { captureOverlay.toggle() }
        function open(): void { captureOverlay.open = true }
        function close(): void { captureOverlay.open = false }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { lockScreen.lock() }
        function state(): string { return lockScreen.locked ? "locked" : "unlocked" }
    }

    Bar {
        onOpenPage: name => Launcher.openNamed(name)
        onToggleControl: Launcher.toggle()
    }

    Loader {
        active: BarPopup.open || BarPopup.closing
        sourceComponent: ModulePopup {
            barWindow: BarPopup.barWindow
            target: BarPopup.target
        }
    }

    Overview {}

    Island {}

    Dock {}

    // qs -c shell ipc call notifications toggle
    IpcHandler {
        target: "notifications"

        function toggle(): void { Notifications.toggleCenter() }
        function open(): void   { Notifications.centerOpen = true }
        function close(): void  { Notifications.centerOpen = false }
        function dnd(): void    { Notifications.toggle() }
        function clear(): void  { Notifications.clearAll() }
    }

    // quickshell -c shell ipc call overview toggle
    IpcHandler {
        target: "overview"

        function toggle(): void { OverviewState.toggle() }
        function open(): void   { OverviewState.open() }
        function close(): void  { OverviewState.close() }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void { BarState.shown = !BarState.shown }
        function show(): void   { BarState.shown = true }
        function hide(): void   { BarState.shown = false }

        function layout(name: string): string {
            return BarState.set(name) ? "ok" : "unknown layout: " + name;
        }
        function next(): string { BarState.next(); return BarState.current; }
        function current(): string { return BarState.current; }
        function layouts(): string { return BarState.names.join("\n"); }
    }

    // qs -c shell ipc call dock toggle
    IpcHandler {
        target: "dock"

        function toggle(): void  { DockState.toggle() }
        function enable(): void  { DockState.setVisible(true) }
        function disable(): void { DockState.setVisible(false) }
        function autohide(): void { DockState.setMode("autohide") }
        function setMode(value: string): string { return DockState.setMode(value) ? "ok" : "invalid mode" }
        function state(): string { return DockState.mode }
    }

    LauncherWindow { id: launcherWindow }

    IpcHandler {
        target: "launcher"
        function toggle(): void { Launcher.toggle() }
        function open(): void   { Launcher.open = true }
        function close(): void  { Launcher.open = false }
        function enter(id: string): void { Launcher.enterSection(id) }
        function page(name: string): void { Launcher.openNamed(name) }
        function back(): void   { Launcher.goBack() }
        function state(): string {
            return "open=" + Launcher.open
                + " visible=" + launcherWindow.visible
                + " drilled=" + Launcher.drilled
                + " section=" + Launcher.section
                + " screen=" + (launcherWindow.screen ? launcherWindow.screen.name : "none")
                + " screens=" + Quickshell.screens.length
                + " results=" + Launcher.search("").length;
        }
    }
}
