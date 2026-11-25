pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Personal preferences: paths and external commands. Adjust them to your setup.
Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property string nixConfigDir: home + "/.config/nixconfig"

    // ── Kuro: central settings ───────────────────────────────────────
    // Source of truth for colors, fonts and look. `kurogen` renders it to
    // theme.json (shell), hypr/kuro.lua and kitty/kuro.conf.
    readonly property string kuroConfig: home + "/.config/kuro/kuro.toml"
    readonly property string kuroThemesDir: home + "/.config/kuro/themes"
    readonly property string kuroCacheDir: home + "/.cache/kuro"
    readonly property string kuroTheme: kuroCacheDir + "/theme.json"
    readonly property string kurogen: home + "/.config/quickshell/shell/bin/kurogen"
    readonly property string hyprKuro: home + "/.config/hypr/kuro.lua"
    readonly property string kittyKuro: home + "/.config/kitty/kuro.conf"

    // Filled from theme.json (the selected colorscheme list).
    property var kuroSchemes: []
    property string kuroScheme: ""
    property string kuroSchemeName: ""
    property var kuroFonts: ({})

    // ── pywal ────────────────────────────────────────────────────────
    // false = built-in palette in Theme.qml (the scheme currently in use).
    // true  = Theme.qml follows this file; colors change when pywal rewrites it.
    readonly property bool usePywal: false
    readonly property string walColors: home + "/.cache/wal/colors.json"

    // ── Wallpaper: uses your own script ──────────────────────────────
    // Folder shown as a grid on the Wallpaper page.
    // Same as WALL_DIR in the wallset script.
    property string wallpaperDir: home + "/Pictures/Wallpaper"
    readonly property string wallpaperThumbCache: home + "/.cache/quickshell/wallpaper-thumbnails"
    readonly property string wallpaperThumbScript: home + "/.config/quickshell/shell/bin/wallpaper-thumbnails"
    readonly property string wallpaperIndexScript: home + "/.config/quickshell/shell/bin/wallpaper-index"
    readonly property string systemWindowDataScript: home + "/.config/quickshell/shell/bin/system-window-data.py"

    // Backend: called when a thumbnail is clicked. "$1" = image path.
    // Apply directly through the running awww daemon.
    readonly property string wallpaperSet: "awww img --transition-type grow --transition-pos center --transition-duration 1.1 --transition-fps 60 \"$1\""

    // Backend output is written here (not to Quickshell), so processes
    // restarted by the backend (e.g. waybar) aren't tied to Quickshell.
    readonly property string wallpaperLog: home + "/.cache/wallset-backend.log"

    // Frontend: your picker, opened via the "Open picker" button (Control Center is closed too).
    // Same as the SUPER+K binding. Old rofi picker: home + "/.local/bin/wallset"
    property string wallpaperPicker: "qs -c shell ipc call stylepicker wallpaper"

    // App defaults from kuro.toml (overridden by theme.json when present).
    property string fileManager: "dolphin"
    property string menu: "qs -c shell ipc call launcher toggle"

    // ── Clipboard (cliphist) ─────────────────────────────────────────
    readonly property int clipLimit: 80                                  // entries shown
    readonly property string clipCacheDir: home + "/.cache/quickshell/clipboard"   // image thumbnails

    // ── Notifications (Quickshell as daemon, swaync must be disabled) ──
    readonly property string notifPosition: "top-right"     // "top-right" | "bottom-right"
    readonly property int notifTimeout: 6000                 // ms, 0 = never auto-dismiss
    readonly property int notifMaxPopups: 4
    readonly property int notifWidth: 440
    readonly property string notifStateFile: home + "/.cache/quickshell/notif-dnd"
    readonly property string notifHistoryFile: home + "/.cache/quickshell/notif-history.json"
    readonly property string powerAutomationStateFile: home + "/.cache/quickshell/power-automation.json"

    // Calendar todos are stored as Markdown in Documents/Tasks.
    readonly property string todoStateFile: home + "/Documents/Tasks/Todo.md"

    // ── Hyprland ─────────────────────────────────────────────────────
    // The Appearance page writes values to this file. To make it permanent, add
    // `load("quickshell")` at the END of hyprland.lua.
   readonly property string hyprOverrides: home + "/.config/hypr/quickshell.lua"

    // ── Miscellaneous ────────────────────────────────────────────────
    readonly property int nightLightDefault: 4500
    readonly property var lockCommand: ["qs", "-c", "shell", "ipc", "call", "lock", "lock"]

    // ── Bar ──────────────────────────────────────────────────────────
    // Quickshell bar (replaces Waybar). false = not shown at startup;
    // can still be shown via: quickshell -p ~/.config/quickshell/shell ipc call bar toggle
    readonly property bool barEnabled: true
    // Initial layout if none has been chosen yet (see bar/BarState.qml)
    readonly property string barLayout: "full"
    // The last selected layout is stored here
    readonly property string barStateFile: home + "/.cache/quickshell/bar-layout"

    // ── Dock ─────────────────────────────────────────────────────────
    // Full-width bottom dock with the open windows, centered.
    readonly property bool dockEnabled: true
    readonly property int dockHeight: 48
    readonly property string dockStateFile: home + "/.cache/quickshell/dock-state"
    readonly property string dockPinnedFile: home + "/.cache/quickshell/dock-pinned.json"
    // Draw the current wallpaper on external outputs; the desktop surface also
    // handles the wallpaper/theme double-click shortcuts on every monitor.
    readonly property bool backdropExternal: true
    // Run by the launcher button in the bar
    readonly property string launcherCommand: "pkill rofi || rofi -show drun"
    // ── Weather (Open-Meteo, no API key; requires curl + jq) ──────────
    // Shown in the calendar popup + the "weather" bar module.
    readonly property bool weatherEnabled: true
    // Empty = auto location from IP. Fill in if IP geolocation is off, e.g. "-6.2" / "106.8"
    readonly property string weatherLat: ""
    readonly property string weatherLon: ""
    readonly property string weatherCity: ""          // displayed name; empty = from IP
    readonly property int weatherRefreshMinutes: 30
    readonly property string weatherScript: home + "/.config/quickshell/shell/bin/weather"
    readonly property string weatherCache: home + "/.cache/quickshell/weather.json"

    // ── Dynamic island ───────────────────────────────────────────────
    // Shown in the center of the bar for layouts with `island: true` (e.g. the "island" layout)
    readonly property bool islandEnabled: true
    readonly property bool islandOsd: true            // volume & brightness appear in the island
    readonly property bool islandNotifications: true  // notifications appear in the island, not as popups
    readonly property bool islandWorkspaceHint: true  // "Workspace 2" briefly when switching workspaces
    readonly property int islandHeight: 34            // pill height when compact
    readonly property string islandFont: "JetBrainsMono Nerd Font"   // font + icon glyphs, same as the rest of the UI
    readonly property string islandClockFormat: "hh:mm"   // "hh:mm ap" = 04:57 pm
    readonly property bool islandUseTheme: true       // follows the shell palette (not Tide's black-and-white)

    // ── Workspace overview ───────────────────────────────────────────
    readonly property int overviewWorkspaces: 5      // 1..N always shown even when empty
    readonly property int overviewColumns: 5         // workspaces per row
    readonly property bool overviewLive: false       // true = live preview (heavier)

    readonly property bool launcherBuiltin: true
    readonly property string launcherHistory: home + "/.cache/quickshell/launcher.json"
    readonly property string launcherSearchUrl: "https://duckduckgo.com/?q="
    // Terminal used by the launcher for package, container and system actions.
    // Commands are passed as a single `sh -c` argument, so no shell quoting is needed.
    property var terminal: ["kitty", "-e"]
    // A plain interactive terminal (used by dynashell: run `dynashell` inside it).
    readonly property var plainTerminal: ["kitty"]
    // Centered floating terminal for interactive launcher actions.
    readonly property var popupTerminal: ["kitty", "--class", "omarchy-launcher-tui", "-e"]
    // Floating centered kitty for fzf menus (see the launcher-tui Hyprland rule).
    // FZPAC_FINDER is absolute so fzpac finds fzf without depending on PATH.
    readonly property var tuiTerminal: ["env", "FZPAC_FINDER=" + home + "/.local/bin/fzf", "kitty",
                                        "--class", "omarchy-launcher-tui", "-e"]
    readonly property string fzpac: home + "/.config/quickshell/shell/bin/fzpac"
    readonly property string captureScript: home + "/.config/quickshell/shell/bin/capture"
    readonly property string containerStopScript: home + "/.config/quickshell/shell/bin/container-stop"
    readonly property string containerCreateScript: home + "/.config/quickshell/shell/bin/container-create"
    // Imperative dynashell environment and update helpers (bin/ scripts).
    readonly property string dynashellScript: home + "/.config/quickshell/shell/bin/dynashell"
    readonly property string dynashellAddScript: home + "/.config/quickshell/shell/bin/dynashell-add"
    readonly property string dynashellRemoveScript: home + "/.config/quickshell/shell/bin/dynashell-remove"
    readonly property string updateDesktopScript: home + "/.config/quickshell/shell/bin/update-desktop"
    readonly property string updateSystemScript: home + "/.config/quickshell/shell/bin/update-system"
    readonly property string updateFlakeScript: home + "/.config/quickshell/shell/bin/update-flake"
    readonly property string captureStateFile: home + "/.cache/quickshell/gpu-screen-recorder.pid"

    // readonly property string externalMode: "1920x1080@60"

    // ── Mouse battery (2.4 GHz YJX-CHIP receiver, bin/mouse-battery) ──
    readonly property bool mouseBattery: true
    readonly property string mouseBatteryScript: home + "/.config/quickshell/shell/bin/mouse-battery"
    readonly property int mouseBatteryInterval: 60       // seconds
    readonly property int mouseLowBattery: 15            // percent, warns once below this

    // ── Kuro theme.json ──────────────────────────────────────────────
    function expandHome(path) {
        return path.startsWith("~/") ? home + path.slice(1) : path;
    }

    function applyKuro(raw) {
        let j;
        try { j = JSON.parse(raw); } catch (e) { return; }

        const a = j.apps ?? {};
        if (a.terminal) terminal = [a.terminal, "-e"];
        if (a.fileManager) fileManager = a.fileManager;
        if (a.menu) menu = a.menu;
        if (a.wallpaperDir) wallpaperDir = expandHome(a.wallpaperDir);
        if (a.wallpaperPicker) wallpaperPicker = a.wallpaperPicker;

        if (Array.isArray(j.schemes)) kuroSchemes = j.schemes;
        if (j.scheme) kuroScheme = j.scheme;
        if (j.schemeName) kuroSchemeName = j.schemeName;
        if (j.fonts) kuroFonts = j.fonts;
    }

    FileView {
        path: root.kuroTheme
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.applyKuro(text())
    }
}
