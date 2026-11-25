pragma Singleton

import QtQuick
import Quickshell
import qs.config
import qs.bar
import qs.dock
import qs.services

// Live rows for the launcher's control sections. The old Control Center pages
// became these item builders: each row can carry a value, a toggle/slider
// `adjust` function and a normal launcher `run` action.
//
// Item shape (see services/Launcher.qml -> sectionResults):
//   { title, sub, glyph, keys, hint, value, control, active, danger,
//     keepOpen, adjust(dir), run }
Singleton {
    id: root

    function g(cp) { return Icons.g(cp) }
    function pct(v) { return Math.round(v * 100) + "%" }
    function onoff(v) { return v ? "on" : "off" }
    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

    function shq(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function fmtMin(m) {
        m = ((m % 1440) + 1440) % 1440;
        return String(Math.floor(m / 60)).padStart(2, "0") + ":" +
               String(m % 60).padStart(2, "0");
    }

    function stepList(list, current, dir) {
        const i = Math.max(0, list.indexOf(current));
        return list[(i + dir + list.length) % list.length];
    }

    // A pure slider row: ←/→ and the wheel adjust it.
    function slider(o) {
        o.control = "slider";
        o.keepOpen = true;
        o.hint = o.hint ?? "value";
        return o;
    }

    function toggle(o) {
        o.control = "toggle";
        o.keepOpen = true;
        o.hint = o.hint ?? "toggle";
        return o;
    }

    function info(title, value, keys, sub) {
        return {
            title: title,
            sub: sub ?? "Enter copies this value",
            glyph: g(0xF02FD),
            keys: keys + " info information value",
            hint: "info", value: value,
            keepOpen: true,
            run: { type: "copy", text: value }
        };
    }

    function controlItems() {
        const n = Network;
        const a = Audio;
        const items = [
            {
                title: "Layout",
                sub: "Choose the active workspace window layout",
                glyph: Icons.overview,
                keys: "layout tiling dwindle scrolling niri columns",
                hint: "open",
                run: { type: "enterSection", id: "control-layout" }
            },
            {
                title: "System profile",
                sub: "Open the live CPU, memory, disk, Wi-Fi and GPU monitor",
                glyph: Icons.cpu,
                keys: "profile telemetry system monitor cpu memory disk wifi gpu",
                hint: "open",
                run: { type: "cmd", cmd: ["qs", "-c", "shell", "ipc", "call", "monitor", "open"] }
            },
            toggle({
                title: "Wi-Fi",
                sub: n.ssid !== "" ? "Connected to " + n.ssid
                    : n.enabled ? "Wireless network is on" : "Wireless network is off",
                glyph: n.enabled ? Icons.wifiStrength[Math.min(4, Math.floor(n.wifiSignal / 20))] : Icons.wifiOff,
                keys: "wifi wireless network radio nmcli internet",
                value: onoff(n.enabled),
                active: n.enabled,
                run: { type: "callback", fn: () => n.toggle() }
            }),
            toggle({
                title: "Bluetooth",
                sub: !Bluetooth.available ? "No adapter"
                    : Bluetooth.device !== "" ? "Connected to " + Bluetooth.device
                    : Bluetooth.powered ? "Bluetooth is on" : "Bluetooth is off",
                glyph: Bluetooth.powered ? Icons.bluetooth : Icons.bluetoothOff,
                keys: "bluetooth headset pair devices wireless",
                value: Bluetooth.available ? onoff(Bluetooth.powered) : "unavailable",
                active: Bluetooth.powered,
                run: { type: "callback", fn: () => Bluetooth.toggle() }
            }),
            {
                title: "Sound",
                sub: "Volume, microphone and output devices",
                glyph: a.muted ? Icons.volumeOff : Icons.volumeForLevel(a.volume, false),
                keys: "sound audio volume speaker microphone mic mute wpctl",
                hint: "open",
                value: a.muted ? "muted" : pct(a.volume),
                active: !a.muted,
                run: { type: "enterSection", id: "dev-sound" }
            },
            {
                title: "Display",
                sub: "Brightness, night light and external screens",
                glyph: Icons.brightness,
                keys: "display brightness night light screen monitor resolution",
                hint: "open",
                value: Brightness.available ? pct(Brightness.value) : "display",
                run: { type: "enterSection", id: "dev-display" }
            }
        ];
        return items;
    }

    function layoutItems() {
        LayoutMode.refresh();
        const descriptions = {
            dwindle: "Split windows into a binary tiling tree",
            scrolling: "Niri-style horizontal tape of window columns"
        };
        return LayoutMode.modes.map(mode => ({
            title: mode.charAt(0).toUpperCase() + mode.slice(1),
            sub: descriptions[mode],
            glyph: Icons.overview,
            keys: "layout tiling " + mode + (mode === "scrolling" ? " niri columns horizontal" : ""),
            hint: LayoutMode.current === mode ? "active" : "set",
            active: LayoutMode.current === mode,
            keepOpen: true,
            run: { type: "callback", fn: () => LayoutMode.set(mode) }
        }));
    }

    // ── Profile / system information ─────────────────────────────────
    function profileItems() {
        return [{
            title: "Open system monitor",
            sub: "Live CPU, memory, disk, Wi-Fi and GPU graphs",
            glyph: Icons.cpu,
            keys: "system monitor profile cpu memory disk wifi gpu live graph",
            hint: "open",
            run: { type: "cmd", cmd: ["qs", "-c", "shell", "ipc", "call", "monitor", "open"] }
        }];
    }

    // ── Network (nmcli) ──────────────────────────────────────────────
    function networkItems() {
        const n = Network;
        const out = [];

        out.push(toggle({
            title: "Wi-Fi", value: onoff(n.enabled),
            sub: n.enabled ? (n.ssid !== "" ? "Connected to " + n.ssid : "On")
                           : (n.ethConnected ? "Off — online through Ethernet" : "Off"),
            glyph: n.enabled ? Icons.wifi : Icons.wifiOff,
            keys: "wifi wi-fi wireless radio network",
            run: { type: "callback", fn: () => n.toggle() }
        }));

        if (n.enabled) {
            out.push({
                title: "Scan for networks",
                sub: "Refresh the Wi-Fi list",
                glyph: Icons.refresh, keys: "scan search wifi networks",
                hint: "scan", value: n.scanning ? "scanning…" : "",
                keepOpen: true,
                run: { type: "callback", fn: () => n.scan(true) }
            });
        }

        if (n.ssid !== "") {
            out.push({
                title: "Disconnect Wi-Fi",
                sub: "Currently connected to " + n.ssid,
                glyph: Icons.wifiOff, keys: "disconnect wifi network offline",
                hint: "network", active: true, keepOpen: true,
                run: { type: "callback", fn: () => n.disconnect() }
            });
        }

        out.push(info("Ethernet",
            !n.ethDevice ? "not connected"
            : n.ethConnected ? "connected  ·  " + n.ethIp + "  ·  " + n.ethSpeed
            : "cable unplugged",
            "ethernet lan cable wired network", "Wired connection"));

        if (n.error !== "") {
            out.push(info("Last error", n.error, "error network", "nmcli error"));
        }

        for (const net of n.networks) {
            const secured = net.secure && !net.known && !net.active;
            out.push({
                title: net.ssid,
                sub: net.active ? "Connected"
                    : secured ? "Secured  ·  opens a password prompt in a terminal"
                    : net.known ? "Saved network  ·  " + net.security
                    : "Open network  ·  " + net.security,
                glyph: net.active ? Icons.wifi : Icons.wifiOff,
                keys: net.ssid + " wifi network " + net.security + (net.known ? " saved" : ""),
                hint: net.active ? "connected" : net.signal + "%",
                value: net.active ? "connected" : net.signal + "%",
                active: net.active, keepOpen: true,
                run: net.active
                    ? { type: "callback", fn: () => n.disconnect() }
                    : secured
                        ? { type: "terminal",
                            cmd: "nmcli device wifi connect " + shq(net.ssid) + " --ask" }
                        : { type: "callback", fn: () => n.connect(net, "") }
            });
        }

        if (n.enabled && n.networks.length === 0) {
            out.push(info("No networks", n.scanning ? "Scanning…" : "Nothing in range",
                          "wifi empty", "Scan again to refresh"));
        }
        return out;
    }

    // ── Bluetooth (bluetoothctl) ─────────────────────────────────────
    function bluetoothItems() {
        const b = Bluetooth;
        const out = [toggle({
            title: "Bluetooth", value: onoff(b.powered),
            sub: !b.available ? "No adapter"
                : b.powered ? (b.device !== "" ? "Connected to " + b.device : "On")
                : "Off",
            glyph: b.powered ? Icons.bluetooth : Icons.bluetoothOff,
            keys: "bluetooth radio wireless devices",
            run: { type: "callback", fn: () => b.toggle() }
        })];

        for (const d of b.devices) {
            out.push({
                title: d.name, sub: d.mac,
                glyph: d.connected ? Icons.bluetoothOn : Icons.bluetooth,
                keys: d.name + " " + d.mac + " bluetooth device",
                hint: d.connected ? "connected" : "connect",
                value: d.connected ? "connected" : "connect",
                active: d.connected, keepOpen: true,
                run: { type: "callback", fn: () => b.toggleDevice(d) }
            });
        }

        if (b.devices.length === 0) {
            out.push(info("No paired devices",
                          b.powered ? "Pair one with bluetoothctl or blueman" : "Turn Bluetooth on",
                          "bluetooth pair", "Paired devices appear here"));
        }
        return out;
    }

    // ── Sound (wpctl) ────────────────────────────────────────────────
    function soundItems() {
        const a = Audio;
        const out = [];

        out.push(slider({
            title: "Output volume", value: (a.muted ? "muted · " : "") + pct(a.volume),
            sub: "←/→ or wheel adjust  ·  Enter mutes",
            glyph: a.muted ? Icons.volumeOff : Icons.volume,
            keys: "volume sound audio speaker output mute",
            adjust: d => a.setVolume(clamp(a.volume + d * 0.05, 0, 1)),
            run: { type: "callback", fn: () => a.toggleMute() }
        }));

        if (a.hasMic) {
            out.push(slider({
                title: "Microphone", value: (a.micMuted ? "muted · " : "") + pct(a.micVolume),
                sub: "←/→ or wheel adjust  ·  Enter mutes",
                glyph: a.micMuted ? Icons.micOff : Icons.mic,
                keys: "microphone mic input volume mute",
                adjust: d => a.setMicVolume(clamp(a.micVolume + d * 0.05, 0, 1)),
                run: { type: "callback", fn: () => a.toggleMicMute() }
            }));
        }

        for (const d of a.sinks) {
            out.push({
                title: d.name, sub: "Output device",
                glyph: Icons.speaker, keys: d.name + " output sink speaker device",
                hint: d.isDefault ? "default" : "use",
                value: d.isDefault ? "default" : "",
                active: d.isDefault, keepOpen: true,
                run: { type: "callback", fn: () => a.setDefault(d, true) }
            });
        }
        for (const d of a.sources) {
            out.push({
                title: d.name, sub: "Input device",
                glyph: Icons.mic, keys: d.name + " input source microphone device",
                hint: d.isDefault ? "default" : "use",
                value: d.isDefault ? "default" : "",
                active: d.isDefault, keepOpen: true,
                run: { type: "callback", fn: () => a.setDefault(d, false) }
            });
        }
        return out;
    }

    // ── Display ──────────────────────────────────────────────────────
    function displayItems() {
        const out = [];

        if (Brightness.available) {
            out.push(slider({
                title: "Brightness", value: pct(Brightness.value),
                sub: "←/→ or wheel adjust",
                glyph: Icons.brightness, keys: "brightness screen backlight display",
                adjust: d => Brightness.setValue(clamp(Brightness.value + d * 0.05, 0, 1)),
                run: { type: "callback",
                       fn: () => Brightness.setValue(clamp(Brightness.value + 0.05, 0, 1)) }
            }));
        } else {
            out.push(info("Brightness", "no backlight", "brightness display",
                          "External monitor or brightnessctl missing"));
        }

        out.push(toggle({
            title: "Night light", value: onoff(NightLight.active),
            sub: !NightLight.available ? "hyprsunset not installed"
                : NightLight.active ? "On · " + NightLight.temperature + "K" : "Off",
            glyph: Icons.night, keys: "night light warm hyprsunset",
            run: { type: "callback", fn: () => NightLight.toggle() }
        }));

        if (NightLight.available) {
            out.push(slider({
                title: "Night light temperature",
                value: NightLight.temperature + "K",
                sub: "Lower is warmer  ·  ←/→ adjust",
                glyph: Icons.night, keys: "night light temperature kelvin warm",
                adjust: d => NightLight.setTemperature(
                    clamp(NightLight.temperature + d * 100, 2500, 6500)),
                run: { type: "callback",
                       fn: () => NightLight.setTemperature(
                           clamp(NightLight.temperature + 100, 2500, 6500)) }
            }));
            out.push(toggle({
                title: "Night light schedule", value: onoff(NightLight.scheduled),
                sub: "On at " + NightLight.onTime + "  ·  off at " + NightLight.offTime,
                glyph: Icons.night, keys: "night light schedule timer automatic",
                run: { type: "callback", fn: () => NightLight.setScheduled(!NightLight.scheduled) }
            }));
            out.push(slider({
                title: "Schedule: turn on", value: NightLight.onTime,
                sub: "←/→ moves by 15 minutes",
                glyph: Icons.night, keys: "night light schedule on start time",
                adjust: d => NightLight.setOn(NightLight.onMinutes + d * 15),
                run: { type: "callback", fn: () => NightLight.setOn(NightLight.onMinutes + 15) }
            }));
            out.push(slider({
                title: "Schedule: turn off", value: NightLight.offTime,
                sub: "←/→ moves by 15 minutes",
                glyph: Icons.night, keys: "night light schedule off end time",
                adjust: d => NightLight.setOff(NightLight.offMinutes + d * 15),
                run: { type: "callback", fn: () => NightLight.setOff(NightLight.offMinutes + 15) }
            }));
        }

        const d = Displays;
        for (const m of [
            { id: "extend", label: "Extend", sub: "Second screen to the right" },
            { id: "mirror", label: "Mirror", sub: "Same picture on both screens" },
            { id: "off", label: "Laptop only", sub: "Switch the external screen off" }
        ]) {
            out.push({
                title: m.label, sub: m.sub,
                glyph: Icons.monitor, keys: m.label + " external display mode " + m.id,
                hint: d.mode === m.id ? "active" : "display",
                value: d.mode === m.id ? "active" : "",
                active: d.mode === m.id, keepOpen: true,
                run: { type: "callback", fn: () => d.setMode(m.id) }
            });
        }

        if (d.connected && d.resolutions.length > 0) {
            for (const r of d.resolutions) {
                const parts = r.split("@");
                out.push({
                    title: parts[0] + " · " + Math.round(parseFloat(parts[1] ?? "0")) + "Hz",
                    sub: "External display resolution",
                    glyph: Icons.monitor, keys: "resolution external display tv " + r,
                    hint: d.resolution === r ? "active" : "mode",
                    value: d.resolution === r ? "active" : "",
                    active: d.resolution === r, keepOpen: true,
                    run: { type: "callback", fn: () => d.setResolution(r) }
                });
            }
            out.push({
                title: "Auto resolution", sub: "Let the display pick its preferred mode",
                glyph: Icons.monitor, keys: "auto preferred resolution display",
                hint: d.resolution === "preferred" ? "active" : "mode",
                value: d.resolution === "preferred" ? "active" : "",
                active: d.resolution === "preferred", keepOpen: true,
                run: { type: "callback", fn: () => d.setResolution("preferred") }
            });
        }

        out.push(info("Display", SystemInfo.resolution, "monitor screen resolution",
                      "Primary display mode"));
        out.push({
            title: "Refresh displays", sub: "Re-read monitor and night light state",
            glyph: Icons.refresh, keys: "refresh displays monitors",
            hint: "instant", keepOpen: true,
            run: { type: "callback", fn: () => { d.refresh(); NightLight.refresh(); } }
        });
        return out;
    }

    // ── Appearance ───────────────────────────────────────────────────
    function appearanceItems() {
        return [
            { title: "Opacity", sub: "Glass or opaque surfaces", glyph: g(0xF0A07), keys: "opacity glass opaque blur", run: { type: "enterSection", id: "appearance-opacity" } },
            { title: "Border", sub: "Sharp or rounded corners", glyph: Icons.settings, keys: "border sharp rounded corners", run: { type: "enterSection", id: "appearance-border" } },
            { title: "Panels", sub: "Dock and panel settings", glyph: Icons.overview, keys: "panels dock bar settings", run: { type: "enterSection", id: "appearance-panels" } },
            { title: "Animations", sub: "Turn animations on or off", glyph: Icons.settings, keys: "animations motion effects", run: { type: "enterSection", id: "appearance-animations" } }
        ];
    }

    function opacityItems() {
        const h = Hypr;
        return [
            { title: "Glass", sub: "Blurred translucent surfaces", glyph: g(0xF0A07), keys: "glass blur translucent appearance", hint: h.blur ? "active" : "enable", value: h.blur ? "active" : "", active: h.blur, keepOpen: true, run: { type: "callback", fn: () => root.setOpacityMode(true) } },
            { title: "Opaque", sub: "Solid surfaces without blur", glyph: Icons.settings, keys: "opaque solid no blur appearance", hint: !h.blur ? "active" : "enable", value: !h.blur ? "active" : "", active: !h.blur, keepOpen: true, run: { type: "callback", fn: () => root.setOpacityMode(false) } }
        ];
    }

    function borderItems() {
        const h = Hypr;
        return [
            { title: "Sharp", sub: "Square window corners", glyph: Icons.settings, keys: "sharp square corners border appearance", hint: h.rounding === 0 ? "active" : "enable", value: h.rounding === 0 ? "active" : "", active: h.rounding === 0, keepOpen: true, run: { type: "callback", fn: () => h.set("rounding", 0) } },
            { title: "Rounded", sub: "Rounded window corners", glyph: Icons.settings, keys: "round rounded corners border appearance", hint: h.rounding > 0 ? "active" : "enable", value: h.rounding > 0 ? "active" : "", active: h.rounding > 0, keepOpen: true, run: { type: "callback", fn: () => h.set("rounding", 10) } }
        ];
    }

    function panelItems() {
        return [
            { title: "Dock settings", sub: "Visibility and autohide", glyph: Icons.overview, keys: "dock taskbar settings", run: { type: "enterSection", id: "appearance-dock-settings" } },
            { title: "Panel settings", sub: "Bar visibility and layout", glyph: Icons.overview, keys: "panel bar settings", run: { type: "enterSection", id: "appearance-panel-settings" } }
        ];
    }

    function setOpacityMode(glass) {
        Hypr.set("blur", glass);
        Quickshell.execDetached([
            Config.kurogen, "set", "terminal.opacity", glass ? "0.78" : "1.0"
        ]);
    }

    function dockSettingItems() {
        const out = [];
        for (const mode of [
            { id: "enabled", title: "Dock: Always show", sub: "Visible and reserves screen space" },
            { id: "disabled", title: "Dock: Off", sub: "Keep the dock hidden" },
            { id: "autohide", title: "Dock: Autohide", sub: "Reveal it at the bottom screen edge" }
        ]) out.push({
            title: mode.title, sub: mode.sub, glyph: Icons.overview,
            keys: "dock taskbar windows bottom show hide autohide",
            hint: DockState.mode === mode.id ? "active" : "set",
            value: DockState.mode === mode.id ? "active" : "",
            active: DockState.mode === mode.id, keepOpen: true,
            run: { type: "callback", fn: () => DockState.setMode(mode.id) }
        });
        return out;
    }

    function panelSettingItems() {
        const out = [{
            title: "Cycle bar layout", sub: "Switch to the next configured panel layout",
            glyph: Icons.overview, keys: "bar panel layout next cycle",
            hint: BarState.current, keepOpen: true,
            run: { type: "barNext" }
        }, {
            title: "Show bar", sub: "Show or hide the top panel",
            glyph: Icons.overview, keys: "bar panel status show hide",
            hint: BarState.shown ? "active" : "show", value: BarState.shown ? "active" : "",
            active: BarState.shown, keepOpen: true,
            run: { type: "callback", fn: () => BarState.shown = !BarState.shown }
        }];
        for (const name of BarState.names) {
            const l = BarState.layouts[name];
            out.push({
                title: name + " panel", sub: l.style + "  ·  " + l.height + "px",
                glyph: Icons.overview, keys: name + " panel bar layout " + l.style,
                hint: BarState.current === name ? "active" : "layout",
                value: BarState.current === name ? "active" : "",
                active: BarState.current === name, keepOpen: true,
                run: { type: "barSet", name: name }
            });
        }
        return out;
    }

    function animationItems() {
        const h = Hypr;
        const out = [];
        for (const enabled of [true, false]) out.push({
            title: enabled ? "On" : "Off",
            sub: enabled ? "Enable motion and transitions" : "Disable motion and transitions",
            glyph: Icons.settings,
            keys: "animations " + (enabled ? "on enable" : "off disable") + " motion effects",
            hint: h.animations === enabled ? "active" : "set",
            value: h.animations === enabled ? "active" : "",
            active: h.animations === enabled, keepOpen: true,
            run: { type: "callback", fn: () => h.set("animations", enabled) }
        });
        return out;
    }

    // ── Notifications ────────────────────────────────────────────────
    function notificationItems() {
        const n = Notifications;
        const out = [toggle({
            title: "Do not disturb", value: onoff(n.dnd),
            sub: n.dnd ? "Popups hidden, except critical" : "Popups shown",
            glyph: n.dnd ? Icons.bellOff : Icons.bell,
            keys: "notifications dnd do not disturb mute",
            run: { type: "callback", fn: () => n.toggle() }
        }), {
            title: "Clear all notifications",
            sub: n.count + " notification" + (n.count === 1 ? "" : "s"),
            glyph: Icons.trash, keys: "notifications clear dismiss all",
            hint: "clear", danger: true, keepOpen: true,
            run: { type: "callback", fn: () => n.clearAll() }
        }, {
            title: n.centerOpen ? "Close notification panel" : "Open notification panel",
            sub: "The popup list below the bar",
            glyph: Icons.bell, keys: "notification center panel popups",
            hint: "panel", keepOpen: true,
            run: { type: "callback", fn: () => n.toggleCenter() }
        }];

        for (const item of n.list) {
            out.push({
                title: item.summary || item.appName || "Notification",
                sub: (item.appName ? item.appName + "  ·  " : "") +
                     (item.body ?? "").replace(/\s+/g, " ").slice(0, 120),
                glyph: Icons.bell,
                keys: (item.summary ?? "") + " " + (item.body ?? "") + " " +
                      (item.appName ?? "") + " notification",
                hint: "open", value: n.ago(item.id),
                run: { type: "callback", fn: () => n.activate(item) }
            });
        }
        return out;
    }

    // ── Clipboard ────────────────────────────────────────────────────
    function clipboardItems() {
        const c = Clipboard;
        const out = [{
            title: "Clear clipboard history",
            sub: c.items.length + " entries",
            glyph: Icons.trash, keys: "clipboard clear wipe history",
            hint: "clear", danger: true, keepOpen: true,
            run: { type: "callback", fn: () => c.wipe() }
        }, {
            title: "Refresh history", sub: "Re-read cliphist",
            glyph: Icons.refresh, keys: "clipboard refresh reload",
            hint: "instant", keepOpen: true,
            run: { type: "callback", fn: () => c.refresh() }
        }];

        for (const item of c.items) {
            out.push({
                title: item.image ? "Image" : item.text.replace(/\s+/g, " ").slice(0, 120),
                sub: item.image ? "Image  ·  " + item.meta : "Enter to copy",
                icon: item.thumb, glyph: Icons.clipboard,
                keys: (item.image ? "image " + item.meta : item.text) + " clipboard",
                hint: "copy",
                run: { type: "clip", item: item }
            });
        }
        return out;
    }

    // ── Keybinds ─────────────────────────────────────────────────────
    function keybindItems() {
        const out = Keybinds.binds.map(b => ({
            title: b.keys.join(" "),
            sub: (b.submap !== "" ? "[" + b.submap + "] " : "") + b.desc,
            glyph: Icons.keyboard,
            keys: b.keys.join(" ") + " " + b.desc + " " + b.submap + " keybind shortcut",
            hint: "copy", keepOpen: true,
            run: { type: "copy", text: b.keys.join(" ") + "  " + b.desc }
        }));
        if (out.length === 0) {
            out.push({
                title: "Refresh keybinds", sub: "Read them from hyprctl",
                glyph: Icons.refresh, keys: "keybinds refresh",
                hint: "instant", keepOpen: true,
                run: { type: "callback", fn: () => Keybinds.refresh() }
            });
        }
        return out;
    }

    // ── Power & session ──────────────────────────────────────────────
    function powerItems() {
        return [toggle({
            title: "Caffeine",
            sub: Caffeine.active
                ? "On · idle sleep is inhibited"
                : "Off · normal idle and sleep rules apply",
            glyph: g(0xF009E),
            keys: "caffeine keep awake prevent idle sleep suspend inhibit",
            value: onoff(Caffeine.active),
            active: Caffeine.active,
            run: { type: "callback", fn: () => Caffeine.toggle() }
        }), toggle({
            title: "Auto battery saver",
            sub: PowerAutomation.active
                ? "Active · power saver at 30% · brightness stays adjustable"
                : PowerAutomation.enabled
                    ? "Turns on at 30% while unplugged"
                    : "Off · manage profile and brightness manually",
            glyph: Icons.battery,
            keys: "automatic auto battery saver low battery power profile brightness 30 percent",
            value: onoff(PowerAutomation.enabled),
            active: PowerAutomation.enabled,
            run: { type: "callback", fn: () => PowerAutomation.setEnabled(!PowerAutomation.enabled) }
        }), {
            title: "Lock", sub: "Start the lock screen",
            glyph: Icons.lock, keys: "lock screen session",
            hint: "session", check: "command -v qs >/dev/null",
            run: { type: "cmd", cmd: Config.lockCommand }
        }, {
            title: "Suspend", sub: "Sleep until the next wake",
            glyph: Icons.suspend, keys: "suspend sleep session",
            hint: "session", run: { type: "cmd", cmd: ["systemctl", "suspend"] }
        }, {
            title: "Log out", sub: "End the Hyprland session",
            glyph: Icons.logout, keys: "logout log out exit session",
            hint: "session", danger: true,
            run: { type: "cmd", cmd: ["hyprctl", "dispatch", "exit"] }
        }, {
            title: "Restart", sub: "Reboot the computer",
            glyph: Icons.reboot, keys: "reboot restart session",
            hint: "power", danger: true,
            run: { type: "cmd", cmd: ["systemctl", "reboot"] }
        }, {
            title: "Shut down", sub: "Power off the computer",
            glyph: Icons.power, keys: "shutdown power off session",
            hint: "power", danger: true,
            run: { type: "cmd", cmd: ["systemctl", "poweroff"] }
        }];
    }
}
