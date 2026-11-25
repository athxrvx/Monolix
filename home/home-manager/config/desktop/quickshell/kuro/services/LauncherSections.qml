pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Declarative catalogue for the launcher. This is now the only settings UI:
// the old Control Center pages live here as nested sections.
//
// Result shape used by the UI:
//   { title, sub, glyph, keys, hint, danger, check?, run: { type, ... } }
// Live device rows are added by services/LauncherControls.qml.
Singleton {
    id: root

    function g(cp) { return Icons.g(cp) }

    readonly property var sections: buildSections()

    function buildSections() {
        return baseSections();
    }

    function fontFamilyItem(id, title, family) {
        const selected = Config.kuroFonts.ui === family && Config.kuroFonts.terminal === family;
        return {
            id: id,
            title: title,
            sub: family + " · terminal, shell, and bar",
            glyph: "Aa",
            keys: "font typeface family terminal shell bar " + title + " " + family,
            hint: selected ? "active" : "apply",
            value: selected ? "active" : "",
            active: selected,
            run: {
                type: "cmd",
                cmd: [Config.kurogen, "set",
                      "fonts.ui_family", family,
                      "fonts.terminal_family", family]
            }
        };
    }

    function baseSections() {
        return [
        // ── 01 Apps ──────────────────────────────────────────────────
        {
            id: "apps", num: "01", label: "Apps",
            sub: "Installed applications and launchers",
            glyph: g(0xF003B),                                   // md-apps
            keys: "applications launchers desktop entries favorites recent",
            items: [
                // Flea is disabled in this flake.
                // {
                //     id: "appFlea", title: "Flea",
                //     sub: "File manager",
                //     icon: "file://" + Config.home + "/.config/kuro/filemanager/packaging/com.thisisgm.flea.svg",
                //     glyph: g(0xF024B), keys: "flea file manager files browser",
                //     hint: "app",
                //     run: { type: "cmd", cmd: [Config.home + "/.config/hypr/scripts/toggle-filemanager.sh"] }
                // },
                {
                    id: "appMusic", title: "Kuro Music",
                    sub: "MPD library, queue, and playback",
                    glyph: Icons.music, keys: "music player mpd library queue audio",
                    hint: "open", run: { type: "cmd", cmd: ["qs", "-c", "shell", "ipc", "call", "music", "open"] }
                },
                {
                    id: "appAi", title: "AI assistant",
                    sub: "Open the local assistant and Ollama controls",
                    glyph: Icons.cpu, keys: "ai assistant ollama chat local model sidebar",
                    hint: "open", run: { type: "cmd", cmd: ["qs", "-c", "shell", "ipc", "call", "sidebar", "ai"] }
                },
               {
                    id: "appAll", title: "All applications",
                    sub: "Browse installed .desktop entries",
                    glyph: g(0xF003B), keys: "list browse programs",
                    hint: "apps", run: { type: "section", section: "apps" }
                },
                {
                    id: "appDesktop", title: "Applications folder",
                    sub: "/usr/share/applications",
                    glyph: g(0xF0770), keys: "desktop entries location files",  // md-folder_open
                    hint: "files", check: "test -d /usr/share/applications",
                    run: { type: "url", url: "file:///usr/share/applications" }
                }
            ]
        },

        // ── 02 Control ───────────────────────────────────────────────
        {
            id: "control", num: "02", label: "Control",
            sub: "Window layout, network, Bluetooth, sound and display",
            glyph: Icons.wifi,
            keys: "control devices network wifi bluetooth sound audio display brightness",
            items: []
        },

        // ── 03 Setup ─────────────────────────────────────────────────
        {
            id: "setup", num: "03", label: "Setup",
            sub: "Desktop configuration and installation",
            glyph: g(0xF0493),                                   // md-cog
            keys: "configure install desktop components dotfiles",
            items: [
                // Desktop
                {
                    id: "setupHypr", title: "Hyprland config",
                    configPath: Config.nixConfigDir + "/home/home-manager/config/desktop/hyprland/hyprland.nix",
                    sub: "Desktop · nixconfig/home/home-manager/config/desktop/hyprland/hyprland.nix",
                    glyph: g(0xF08C7), keys: "hyprland compositor desktop config",  // md-arch
                    hint: "config", check: "test -f \"$HOME/.config/hypr/hyprland.lua\"",
                    run: { type: "editor", path: Config.nixConfigDir + "/home/home-manager/config/desktop/hyprland/hyprland.nix" }
                },
                {
                    id: "setupReload", title: "Reload Hyprland",
                    configPath: Config.nixConfigDir + "/home/home-manager/config/desktop/hyprland/hyprland.nix",
                    sub: "Desktop · apply config changes now",
                    glyph: g(0xF0450), keys: "reload refresh desktop config",  // md-refresh
                    hint: "cmd", check: "command -v hyprctl >/dev/null",
                    run: { type: "cmd", cmd: ["hyprctl", "reload"] }
                },
                {
                    id: "setupShell", title: "Shell config",
                    configPath: Config.nixConfigDir + "/home/home-manager/config/shell/zsh/zsh.nix",
                    sub: "Shell · nixconfig/home/home-manager/config/shell/zsh/zsh.nix",
                    glyph: g(0xF018D), keys: "zsh bash fish shell config prompt",  // md-console
                    hint: "config", check: "test -f \"$HOME/.config/zsh/.zshrc\" || test -f \"$HOME/.bashrc\"",
                    run: { type: "editor", path: Config.nixConfigDir + "/home/home-manager/config/shell/zsh/zsh.nix" }
                },
                // Terminal
                {
                    id: "setupKitty", title: "Kitty config",
                    configPath: Config.nixConfigDir + "/home/home-manager/config/desktop/kitty/kitty.nix",
                    sub: "Terminal · nixconfig/home/home-manager/config/desktop/kitty/kitty.nix",
                    glyph: g(0xF489), keys: "kitty terminal font config",  // oct-terminal
                    hint: "config", check: "test -f \"$HOME/.config/kitty/kitty.conf\"",
                    run: { type: "editor", path: Config.nixConfigDir + "/home/home-manager/config/desktop/kitty/kitty.nix" }
                },
                {
                    id: "setupTerm", title: "Open a terminal",
                    configPath: Config.nixConfigDir + "/home/home-manager/config/desktop/kitty/kitty.nix",
                    sub: "Terminal · kitty",
                    glyph: g(0xF489), keys: "terminal shell console kitty",
                    hint: "cmd", check: "command -v kitty >/dev/null",
                    run: { type: "cmd", cmd: ["kitty"] }
                },
                // Development
                {
                    id: "setupGit", title: "Git config",
                    configPath: Config.nixConfigDir + "/home/home-manager/core/development.nix",
                    sub: "Development · nixconfig/home/home-manager/core/development.nix",
                    glyph: g(0xF062C), keys: "git version control development config",
                    hint: "config", check: "test -f \"$HOME/.gitconfig\"",
                    run: { type: "editor", path: Config.nixConfigDir + "/home/home-manager/core/development.nix" }
                },
                {
                    id: "setupHelix", title: "Helix config",
                    configPath: Config.nixConfigDir + "/home/home-manager/config/development/helix/helix.nix",
                    sub: "Development · nixconfig/home/home-manager/config/development/helix/helix.nix",
                    glyph: g(0xF36F), keys: "helix hx editor development config",
                    hint: "config", check: "command -v hx >/dev/null",
                    run: { type: "editor", path: Config.nixConfigDir + "/home/home-manager/config/development/helix/helix.nix" }
                },
                // Input / Audio / Network / Utilities
                {
                    id: "setupKeys", title: "Keybindings",
                    configPath: Config.nixConfigDir + "/home/home-manager/config/desktop/hyprland/conf.d/keybinds.lua",
                    sub: "Input · shortcuts and hotkeys",
                    glyph: Icons.keyboard, keys: "keyboard input shortcuts keybinds",
                    hint: "browse", run: { type: "enterSection", id: "sys-keybinds" }
                },
                {
                    id: "setupAudio", title: "Audio devices",
                    configPath: Config.nixConfigDir + "/modules/audio/audio.nix",
                    sub: "Audio · PipeWire / WirePlumber",
                    glyph: Icons.volume, keys: "pipewire wireplumber sound audio microphone",
                    hint: "browse", check: "command -v wireplumber >/dev/null",
                    run: { type: "enterSection", id: "dev-sound" }
                },
                {
                    id: "setupBt", title: "Bluetooth devices",
                    configPath: Config.nixConfigDir + "/modules/bluetooth/bluetooth.nix",
                    sub: "Input · pair headsets and controllers",
                    glyph: Icons.bluetooth, keys: "bluetooth pair headset earbuds device",
                    hint: "browse", run: { type: "enterSection", id: "dev-bluetooth" }
                },
                {
                    id: "setupNet", title: "NetworkManager",
                    configPath: Config.nixConfigDir + "/modules/system/network.nix",
                    sub: "Networking · Wi-Fi and Ethernet",
                    glyph: Icons.wifi, keys: "networkmanager nmcli wifi ethernet internet",
                    hint: "browse", check: "command -v nmcli >/dev/null",
                    run: { type: "enterSection", id: "dev-network" }
                },
                {
                    id: "setupShot", title: "Screenshot",
                    configPath: Config.nixConfigDir + "/home/home-manager/config/desktop/hyprland/hyprland.nix",
                    sub: "Utilities · select an area with grim + slurp",
                    glyph: g(0xF0100), keys: "screenshot capture screen grim slurp",  // md-camera
                    hint: "cmd", check: "command -v grim >/dev/null && command -v slurp >/dev/null",
                    run: { type: "shell", cmd: "mkdir -p \"$HOME/Pictures/Screenshots\" && grim -g \"$(slurp)\" \"$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png\"" }
                },
                {
                    id: "setupClip", title: "Clipboard history",
                    configPath: Config.nixConfigDir + "/home/home-manager/config/desktop/hyprland/hyprland.nix",
                    sub: "Utilities · copy and paste manager",
                    glyph: Icons.clipboard, keys: "clipboard copy paste history cliphist",
                    hint: "browse", run: { type: "enterSection", id: "sys-clipboard" }
                },
                {
                    id: "setupNotif", title: "Notifications",
                    configPath: Config.nixConfigDir + "/home/home-manager/config/desktop/quickshell/kuro/quickshell.nix",
                    sub: "Utilities · Do Not Disturb and history",
                    glyph: Icons.bell, keys: "notifications dnd alerts",
                    hint: "browse", run: { type: "enterSection", id: "sys-notifications" }
                },
                // Backup
                {
                    id: "setupBackup", title: "Backup configs",
                    configPath: Config.nixConfigDir + "/flake.nix",
                    sub: "Backup · archive dotfiles to ~/Backups",
                    glyph: g(0xF003C), keys: "backup archive dotfiles configs",  // md-archive
                    hint: "terminal",
                    run: { type: "terminal", cmd: "mkdir -p \"$HOME/Backups\"; tar -czf \"$HOME/Backups/configs-$(date +%Y%m%d).tar.gz\" -C \"$HOME\" .config .local/bin 2>/dev/null; echo 'Backup done:'; ls -lh \"$HOME/Backups\" | tail -n +2; exec bash" }
                },
                {
                    id: "setupRestore", title: "Restore configs",
                    configPath: Config.nixConfigDir + "/flake.nix",
                    sub: "Backup · extract an archive over ~/  (overwrites files)",
                    glyph: g(0xF1259), keys: "restore recover backup configs",  // md-archive_arrow_down
                    hint: "terminal", danger: true,
                    run: { type: "terminal", cmd: "ls -1 \"$HOME/Backups\"/*.tar.gz 2>/dev/null; read -rp 'Archive name: ' f; [ -n \"$f\" ] && tar -xzf \"$HOME/Backups/$f\" -C \"$HOME\"; exec bash" }
                }
            ]
        },

        // ── 04 Containers ────────────────────────────────────────────
        {
            id: "containers", num: "04", label: "Containers",
            sub: "Distrobox environments and GUI apps",
            glyph: g(0xF4B7),                                    // oct-container
            keys: "distrobox podman docker container linux environment",
            items: [
                {
                    id: "boxList", title: "List containers",
                    sub: "Distrobox · names, images and status",
                    glyph: g(0xF4B7), keys: "list show containers distrobox",
                    hint: "terminal", check: "command -v distrobox >/dev/null",
                    run: { type: "terminal", cmd: "distrobox list; exec bash" }
                },
                {
                    id: "boxCreate", title: "Create a container",
                    sub: "Distrobox · pick a base image with fzf",
                    glyph: g(0xF0416), keys: "create new container distrobox image fzf",  // md-plus_box
                    hint: "terminal", danger: true, check: "command -v distrobox >/dev/null",
                    run: { type: "popupTerminal", cmd: Config.containerCreateScript + "; exec bash" }
                },
                {
                    id: "boxPrune", title: "Prune unused images",
                    sub: "Podman · remove dangling container images",
                    glyph: g(0xF01B4), keys: "clean prune images cache podman",
                    hint: "terminal", danger: true, check: "command -v podman >/dev/null",
                    run: { type: "terminal", cmd: "podman image prune -f; exec bash" }
                },
                {
                    id: "boxDocs", title: "Container help",
                    sub: "Distrobox · command reference",
                    glyph: g(0xF05DD), keys: "help docs usage distrobox",  // md-bullseye
                    hint: "terminal", check: "command -v distrobox >/dev/null",
                    run: { type: "terminal", cmd: "distrobox --help; exec bash" }
                }
            ]
        },

        // ── 05 Packages ──────────────────────────────────────────────
        // NixOS cannot install packages imperatively into the system, so
        // package changes go to `dynashell`, a persistent nix shell whose
        // package list is edited from the menu.
        {
            id: "packages", num: "05", label: "Packages",
            sub: "dynashell, updates and Flatpaks",
            glyph: g(0xF03D3),                                   // md-package
            keys: "nix shell dynashell packages update flake flatpak software",
            items: [
                {
                    id: "dynashellOpen", title: "dynashell",
                    sub: "Open a terminal · run dynashell",
                    glyph: g(0xF048B), keys: "dynashell nix shell develop imperative environment",
                    hint: "terminal", run: { type: "plainTerminal" }
                },
                {
                    id: "dynashellAdd", title: "Install to shell",
                    sub: "Add a package to dynashell",
                    glyph: g(0xF03D4), keys: "install add package dynashell nix shell",  // md-package_down
                    hint: "terminal", run: { type: "popupTerminal", cmd: Config.dynashellAddScript + "; exec bash" }
                },
                {
                    id: "dynashellRemove", title: "Remove from shell",
                    sub: "Drop a package from dynashell",
                    glyph: g(0xF03D5), keys: "remove uninstall delete package dynashell",  // md-package_up
                    hint: "terminal", run: { type: "popupTerminal", cmd: Config.dynashellRemoveScript + "; exec bash" }
                },
                {
                    id: "pkgUpdateDesktop", title: "Update desktop",
                    sub: "kuro home  ·  Home Manager only",
                    glyph: g(0xF0450), keys: "update desktop home manager dotfiles",
                    hint: "terminal", danger: true, run: { type: "popupTerminal", cmd: Config.updateDesktopScript }
                },
                {
                    id: "pkgUpdateSystem", title: "Update system",
                    sub: "kuro sync  ·  NixOS + Home Manager",
                    glyph: g(0xF0450), keys: "update upgrade system nixos rebuild",
                    hint: "terminal", danger: true, run: { type: "popupTerminal", cmd: Config.updateSystemScript }
                },
                {
                    id: "pkgUpdateFlake", title: "Update flake",
                    sub: "kuro update  ·  at most once every 10 days",
                    glyph: g(0xF0450), keys: "update flake inputs nix lock",
                    hint: "terminal", danger: true, run: { type: "popupTerminal", cmd: Config.updateFlakeScript }
                },
                {
                    id: "flatUpdate", title: "Flatpak update",
                    sub: "flatpak update  ·  refresh all Flatpaks",
                    glyph: g(0xF324), keys: "flatpak update upgrade",  // linux-flathub
                    hint: "terminal", danger: true, check: "command -v flatpak >/dev/null",
                    run: { type: "popupTerminal", cmd: "flatpak update; exec bash" }
                },
                {
                    id: "flatList", title: "List Flatpaks",
                    sub: "flatpak list  ·  installed applications",
                    glyph: g(0xF324), keys: "flatpak list installed",
                    hint: "terminal", check: "command -v flatpak >/dev/null",
                    run: { type: "popupTerminal", cmd: "flatpak list --app; exec bash" }
                }
            ]
        },

        // ── 06 System ────────────────────────────────────────────────
        {
            id: "system", num: "06", label: "System",
            sub: "Notifications, clipboard and maintenance",
            glyph: g(0xF048B),                                   // md-server
            keys: "system hardware storage logs maintenance notifications clipboard",
            items: [
                {
                    id: "sysOverview", title: "System overview",
                    sub: "OS, kernel, uptime, CPU, memory and battery",
                    glyph: Icons.cpu, keys: "overview os kernel uptime hostname telemetry",
                    hint: "browse", run: { type: "enterSection", id: "dev-profile" }
                },
                {
                    id: "sysNotifications", title: "Notifications",
                    sub: "Do Not Disturb and notification history",
                    glyph: Icons.bell, keys: "notifications dnd alerts history",
                    hint: "browse", run: { type: "enterSection", id: "sys-notifications" }
                },
                {
                    id: "sysClipboardMenu", title: "Clipboard history",
                    sub: "Copy again, or clear the cliphist history",
                    glyph: Icons.clipboard, keys: "clipboard copy paste history cliphist",
                    hint: "browse", run: { type: "enterSection", id: "sys-clipboard" }
                },
                {
                    id: "sysKeybinds", title: "Keybinds",
                    sub: "Every active Hyprland shortcut",
                    glyph: Icons.keyboard, keys: "keybinds shortcuts keys hotkeys",
                    hint: "browse", run: { type: "enterSection", id: "sys-keybinds" }
                },
                {
                    id: "sysInfo", title: "Hardware info",
                    sub: "CPU, GPU, memory, display and system details",
                    glyph: g(0xF0EE0), keys: "hardware cpu gpu ram memory disks fastfetch",  // md-cpu_64_bit
                    hint: "dashboard",
                    run: { type: "cmd", cmd: ["qs", "-c", "shell", "ipc", "call", "monitor", "page", "hardware"] }
                },
                {
                    id: "sysStorage", title: "Disk usage",
                    sub: "Filesystem, mount and capacity usage",
                    glyph: g(0xF02CA), keys: "storage disk usage mounts df space",  // md-harddisk
                    hint: "dashboard",
                    run: { type: "cmd", cmd: ["qs", "-c", "shell", "ipc", "call", "monitor", "page", "storage"] }
                },
                {
                    id: "sysLogs", title: "System logs",
                    sub: "Browse recent boot journal entries",
                    glyph: g(0xF02DA), keys: "logs journal journalctl errors debug",
                    hint: "dashboard",
                    run: { type: "cmd", cmd: ["qs", "-c", "shell", "ipc", "call", "monitor", "page", "logs"] }
                },
                {
                    id: "sysCache", title: "Cache cleanup",
                    sub: "Remove user caches and thumbnails",
                    glyph: g(0xF05B7), keys: "cleanup cache trash thumbnails maintenance",
                    hint: "terminal", danger: true,
                    run: { type: "terminal", cmd: "echo 'Removing thumbnail caches...'; rm -rf \"$HOME/.cache/thumbnails\" \"$HOME/.cache/quickshell/clipboard\"; echo 'Done.'; exec bash" }
                },
                {
                    id: "sysBackup", title: "Backup configs",
                    sub: "Archive dotfiles to ~/Backups",
                    glyph: g(0xF003C), keys: "backup archive configs dotfiles",
                    hint: "terminal",
                    run: { type: "terminal", cmd: "mkdir -p \"$HOME/Backups\"; tar -czf \"$HOME/Backups/configs-$(date +%Y%m%d).tar.gz\" -C \"$HOME\" .config .local/bin 2>/dev/null; echo 'Backup done.'; exec bash" }
                }
            ]
        },

        // ── 07 Style ─────────────────────────────────────────────────
        {
            id: "style", num: "07", label: "Style",
            sub: "Themes, fonts, wallpapers and lock screen",
            glyph: Icons.palette,
            keys: "style colorscheme color scheme wallpaper fonts typography lockscreen appearance",
            items: [
                {
                    id: "styleThemes", title: "Themes",
                    sub: "Open the theme picker",
                    glyph: Icons.palette, keys: "themes colorscheme palette colors",
                    hint: "picker", run: { type: "stylePicker", mode: "theme" }
                },
                {
                    id: "styleFontsMenu", title: "Fonts",
                    sub: "Terminal, shell, and bar font family",
                    glyph: "Aa", keys: "fonts typography typeface terminal shell bar nerd font",
                    hint: "browse", run: { type: "enterSection", id: "style-fonts" }
                },
                {
                    id: "styleWalls", title: "Wallpapers",
                    sub: "Open the wallpaper picker",
                    glyph: Icons.image, keys: "wallpapers background image gallery",
                    hint: "picker", run: { type: "stylePicker", mode: "wallpaper" }
                },
                {
                    id: "styleLockscreen", title: "Lockscreen styles",
                    sub: "Lock screen command and configuration",
                    glyph: Icons.lock, keys: "lockscreen lock screen quickshell style",
                    hint: "browse", run: { type: "enterSection", id: "style-lockscreen" }
                },
                {
                    id: "styleAppearance", title: "Appearance",
                    sub: "Blur, animations and bar layouts",
                    glyph: Icons.settings, keys: "appearance blur animations bar layout",
                    hint: "browse", run: { type: "enterSection", id: "style-appearance" }
                },
                {
                    id: "styleKuro", title: "Edit kuro.toml",
                    sub: "Colorschemes, fonts and desktop settings",
                    glyph: g(0xF0DC9), keys: "kuro config edit settings toml theme fonts",
                    hint: "config", check: "test -f \"$HOME/.config/kuro/kuro.toml\"",
                    run: { type: "editor", path: Config.kuroConfig }
                },
                {
                    id: "styleApply", title: "Apply Kuro settings",
                    sub: "Regenerate Hyprland, kitty and the shell",
                    glyph: g(0xF0450), keys: "apply reload kuro regenerate settings",
                    hint: "instant", keepOpen: true, run: { type: "kuroApply" }
                }
            ]
        },

        // ── 08 Power ─────────────────────────────────────────────────
        {
            id: "power", num: "08", label: "Power",
            sub: "Lock, suspend, log out, restart and shut down",
            glyph: Icons.power,
            keys: "power session battery profile lock suspend logout reboot restart shutdown poweroff",
            items: []
        },

        // ─────────────────────────────────────────────────────────────
        // Control submenus (rows come from services/LauncherControls.qml)
        // ─────────────────────────────────────────────────────────────
        {
            id: "control-layout", label: "Layout", hidden: true,
            sub: "Choose the active workspace window layout", glyph: Icons.overview,
            keys: "layout tiling master dwindle scrolling niri columns",
            items: []
        },
        {
            id: "dev-profile", label: "System profile", hidden: true,
            sub: "Live CPU, memory and GPU monitor", glyph: Icons.cpu,
            keys: "system profile cpu memory temperature uptime battery host kernel",
            items: []
        },
        {
            id: "dev-network", label: "Network", hidden: true,
            sub: "Wi-Fi and Ethernet", glyph: Icons.wifi,
            keys: "network wifi wireless ethernet nmcli scan connect disconnect",
            items: []
        },
        {
            id: "dev-bluetooth", label: "Bluetooth", hidden: true,
            sub: "Radio and paired devices", glyph: Icons.bluetooth,
            keys: "bluetooth radio pair device connect disconnect",
            items: []
        },
        {
            id: "dev-sound", label: "Sound", hidden: true,
            sub: "Volume, microphone and devices", glyph: Icons.volume,
            keys: "sound audio volume mute speaker microphone mic output input device",
            items: []
        },
        {
            id: "dev-display", label: "Display", hidden: true,
            sub: "Brightness, night light and screens", glyph: Icons.brightness,
            keys: "display brightness night light hyprsunset monitor screen resolution external mirror extend",
            items: []
        },

        // ─────────────────────────────────────────────────────────────
        // System submenus
        // ─────────────────────────────────────────────────────────────
        {
            id: "sys-notifications", label: "Notifications", hidden: true,
            sub: "Do Not Disturb and history", glyph: Icons.bell,
            keys: "notifications dnd do not disturb alerts history clear",
            items: []
        },
        {
            id: "sys-clipboard", label: "Clipboard", hidden: true,
            sub: "Clipboard history", glyph: Icons.clipboard,
            keys: "clipboard copy paste history cliphist",
            items: []
        },
        {
            id: "sys-keybinds", label: "Keybinds", hidden: true,
            sub: "Hyprland shortcuts", glyph: Icons.keyboard,
            keys: "keybinds shortcuts keys hotkeys binds",
            items: []
        },
        // ─────────────────────────────────────────────────────────────
        // Style submenus
        // ─────────────────────────────────────────────────────────────
        {
            id: "style-fonts", label: "Fonts", hidden: true,
            sub: "Terminal, shell, and bar typeface", glyph: "Aa",
            keys: "fonts typography typeface terminal shell bar family nerd font",
            items: [
                fontFamilyItem("fontJetBrains", "JetBrains Mono", "JetBrainsMono Nerd Font"),
                fontFamilyItem("fontCascadia", "Cascadia Code", "CaskaydiaCove Nerd Font"),
                fontFamilyItem("fontFira", "Fira Code", "FiraCode Nerd Font"),
                fontFamilyItem("fontIosevka", "Iosevka", "Iosevka Nerd Font"),
                {
                    id: "fontDefault", title: "Reset to default",
                    sub: "JetBrains Mono Nerd Font · terminal, shell, and bar",
                    glyph: "Aa", keys: "fonts reset default original JetBrains Mono Nerd Font",
                    hint: "reset",
                    run: {
                        type: "cmd",
                        cmd: [Config.kurogen, "set",
                              "fonts.ui_family", "JetBrainsMono Nerd Font",
                              "fonts.terminal_family", "JetBrainsMono Nerd Font"]
                    }
                }
            ]
        },
        {
            id: "style-lockscreen", label: "Lockscreen", hidden: true,
            sub: "Quickshell lock screen and password entry", glyph: Icons.lock,
            keys: "lockscreen lock screen quickshell password pam style",
            items: [
                {
                    id: "lockNow", title: "Lock screen",
                    sub: "Blur the wallpaper and lock this session",
                    glyph: Icons.lock, keys: "lock screen session quickshell pam",
                    hint: "session", check: "command -v qs >/dev/null",
                    run: { type: "cmd", cmd: Config.lockCommand }
                },
                {
                    id: "lockConfig", title: "Edit lock screen UI",
                    sub: "Quickshell/shell/lock/LockScreen.qml",
                    glyph: g(0xF0DC9), keys: "quickshell config lock screen edit qml",
                    hint: "config", check: "test -f \"$HOME/.config/quickshell/shell/lock/LockScreen.qml\"",
                    run: { type: "editor", path: Config.home + "/.config/quickshell/shell/lock/LockScreen.qml" }
                }
            ]
        },
        {
            id: "style-appearance", label: "Appearance", hidden: true,
            sub: "Hyprland and bar appearance", glyph: Icons.settings,
            keys: "appearance gaps border rounding blur animations bar layout colorscheme",
            items: []
        },
        {
            id: "appearance-opacity", label: "Opacity", hidden: true,
            sub: "Glass or opaque surfaces", glyph: Icons.settings, keys: "opacity glass opaque", items: []
        },
        {
            id: "appearance-border", label: "Border", hidden: true,
            sub: "Sharp or rounded corners", glyph: Icons.settings, keys: "border sharp rounded", items: []
        },
        {
            id: "appearance-panels", label: "Panels", hidden: true,
            sub: "Dock and panel settings", glyph: Icons.overview, keys: "panels dock bar", items: []
        },
        {
            id: "appearance-dock-settings", label: "Dock settings", hidden: true,
            sub: "Dock visibility and autohide", glyph: Icons.overview, keys: "dock taskbar", items: []
        },
        {
            id: "appearance-panel-settings", label: "Panel settings", hidden: true,
            sub: "Bar visibility and layout", glyph: Icons.overview, keys: "panel bar", items: []
        },
        {
            id: "appearance-animations", label: "Animations", hidden: true,
            sub: "Turn animations on or off", glyph: Icons.settings, keys: "animations motion", items: []
        }
        ];
    }

    // Status probes for the Setup section (installed / missing).
    function checksFor(sectionId) {
        const s = sections.find(x => x.id === sectionId);
        return s ? s.items.filter(i => i.check).map(i => ({ id: i.id, cmd: i.check })) : [];
    }
}
