//@ pragma UseQApplication
// Entry point. Run:        quickshell -p ~/.config/quickshell/shell
// Toggle:                  quickshell -p ~/.config/quickshell/shell ipc call controlcenter toggle
// Bar on/off:              quickshell -p ~/.config/quickshell/shell ipc call bar toggle
// Change bar layout:       quickshell -p ~/.config/quickshell/shell ipc call bar layout float

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
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
import qs.music

ShellRoot {
    // Instantiate the kuro.toml watcher/generator for the whole session.
    property bool kuroReady: Kuro.ready

    // Battery automation must run even while the Power page is closed.
    property bool powerAutomationReady: PowerAutomation.loaded

    Popups {}
    NotifCenter {}
    StylePicker { id: stylePicker }
    SystemMonitor { id: systemMonitor }
    SidebarWindow { id: aiSidebar }
    MusicPlayerWindow { id: musicPlayer }

    Connections {
        target: AiAppletState
        function onOpenRequested(item, window) { BarPopup.show("ai", item, window) }
        function onToggleRequested(item, window) { BarPopup.toggle("ai", item, window) }
    }

    Connections {
        target: BarPopup
        function onOpenChanged() { aiSidebar.syncFromBar() }
        function onKindChanged() { aiSidebar.syncFromBar() }
        function onTargetChanged() { aiSidebar.syncFromBar() }
        function onBarWindowChanged() { aiSidebar.syncFromBar() }
    }

    IpcHandler {
        target: "sidebar"
        function toggle(): void { AiAppletState.toggle() }
        function open(): void { AiAppletState.open() }
        function close(): void { BarPopup.close() }
        function ai(): void { AiAppletState.open() }
    }

    IpcHandler {
        target: "idle"
        function screenOff(): void { Hyprland.dispatch("dpms off") }
        function screenOn(): void { Hyprland.dispatch("dpms on") }
    }

    Connections {
        target: Music
        function onToggleRequested() { musicPlayer.toggle() }
        function onOpenRequested() { musicPlayer.openWindow() }
    }

    IpcHandler {
        target: "music"
        function toggle(): void { musicPlayer.toggle() }
        function open(): void { musicPlayer.openWindow() }
        function close(): void { musicPlayer.visible = false }
        function refresh(): void { Music.refresh() }
    }

    IpcHandler {
        target: "caffeine"
        function toggle(): void { Caffeine.toggle() }
        function state(): string { return Caffeine.active ? "on" : "off" }
    }

    IpcHandler {
        target: "layout"
        function cycle(): void { LayoutMode.cycle() }
        function refresh(): void { LayoutMode.refresh() }
        function state(): string { return LayoutMode.current }
    }

    IpcHandler {
        target: "monitor"
        function open(): void { systemMonitor.openWindow() }
        function page(name: string): void { systemMonitor.openPage(name) }
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
        active: (BarPopup.open || BarPopup.closing) && BarPopup.kind !== "ai"
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
