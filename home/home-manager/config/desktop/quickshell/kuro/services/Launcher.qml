pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.bar

// Omarchy-style launcher engine: nested sections + one global search.
//
//   firefox        fuzzy match on app name / category / executable
//   = 12*7         calculator (also on plain math like 2^10)
//   reboot         actions from every section, dangerous ones need a second Enter
//   :clip text     clipboard history        :wall name   wallpapers
//   :file name     find files in $HOME       :win name    open windows
//   > command      run in background         ? query      web search
//
// This is the only control surface: every setting from the old Control Center
// is a section here (Control, System, Style). The catalogue lives in
// services/LauncherSections.qml and the live device controls in
// services/LauncherControls.qml.
Singleton {
    id: root

    property bool open: false
    function toggle() { open = !open; }

    // Old Control Center page names -> launcher sections (bar right-clicks,
    // the desktop clock and `ipc call launcher page` still use them).
    readonly property var pageSections: ({
        profile: "dev-profile",
        network: "dev-network",
        bluetooth: "dev-bluetooth",
        sound: "dev-sound",
        display: "dev-display",
        appearance: "style-appearance",
        fonts: "style-fonts",
        lockscreen: "style-lockscreen",
        clipboard: "sys-clipboard",
        notifications: "sys-notifications",
        power: "power",
        keybinds: "sys-keybinds"
    })

    function openNamed(name) {
        if (name === "wallpaper" || name === "themes") {
            open = false;
            Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "stylepicker",
                                     name === "wallpaper" ? "wallpaper" : "theme"]);
            return;
        }
        const id = pageSections[name] ?? name;
        open = true;
        drilled = false;
        trail = [];
        enterSection(id);
    }

    // ── Sections ─────────────────────────────────────────────────────
    // The launcher is a nested menu: root categories, then any number of
    // submenus (`trail` is the stack of parents). `drilled` = inside one.
    property string section: "apps"
    property bool drilled: false
    property var trail: []
    readonly property var sections: LauncherSections.sections
    readonly property var rootSections: sections.filter(s => !s.hidden)

    function enterSection(id) {
        if (drilled && section === id) return;
        trail = drilled ? trail.concat([section]) : [];
        section = id;
        drilled = true;
        refreshSectionData(id);
    }

    // Keep opening the root launcher lightweight. Refresh expensive/live
    // sources only after the user enters the section that displays them.
    function refreshSectionData(id) {
        switch (id) {
        case "setup": refreshStatus(); break;
        case "containers": refreshContainers(); refreshContainerApps(); break;
        case "control": refreshLive(); break;
        case "dev-network": Network.refresh(); break;
        case "dev-bluetooth": Bluetooth.refresh(); break;
        case "dev-sound": Audio.refresh(); break;
        case "dev-display":
            Brightness.refresh(); NightLight.refresh(); Displays.refresh(); Hypr.refresh();
            break;
        case "style-appearance":
            Brightness.refresh(); NightLight.refresh(); Displays.refresh(); Hypr.refresh(); Wallpaper.refresh();
            break;
        case "power":
            Battery.refresh(); PowerProfile.refresh(); SystemInfo.refresh(); SystemStats.refresh();
            break;
        case "sys-clipboard": Clipboard.refresh(); break;
        }
    }
    function goBack() {
        if (trail.length > 0) {
            section = trail[trail.length - 1];
            trail = trail.slice(0, trail.length - 1);
        } else {
            drilled = false;
        }
    }

    function cycleSection(d) {
        const ids = rootSections.map(s => s.id);
        const at = Math.max(0, ids.indexOf(section));
        section = ids[(at + d + ids.length) % ids.length];
    }
    function sectionAt(i) {
        const s = rootSections[i];
        if (s) section = s.id;
    }

    onOpenChanged: if (open) {
        drilled = false;
        trail = [];
        section = "apps";
    }

    // Keep control values (volume, brightness, CPU…) fresh while the menu is
    // open. The tick also makes search() re-evaluate its bindings.
    property int liveTick: 0
    function refreshLive() {
        Network.refresh();
        Bluetooth.refresh();
        Audio.refresh();
        Brightness.refresh();
        NightLight.refresh();
        Displays.refresh();
        Battery.refresh();
        PowerProfile.refresh();
        SystemInfo.refresh();
        SystemStats.refresh();
        Hypr.refresh();
        Wallpaper.refresh();
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.open
        onTriggered: {
            root.liveTick++;
            if (root.section === "dev-sound") {
                Audio.refresh();
            } else if (root.section === "dev-network") {
                Network.refresh();
            } else if (root.section === "dev-bluetooth") {
                Bluetooth.refresh();
            } else if (root.section === "dev-display" || root.section === "style-appearance") {
                Brightness.refresh();
                NightLight.refresh();
                Displays.refresh();
                Hypr.refresh();
            } else if (root.section === "sys-clipboard") {
                Clipboard.refresh();
            }
        }
    }

    // ── Launch history (frecency) ────────────────────────────────────
    property var history: ({})           // appId -> { n: launches, t: last launch (ms) }

    function frecency(id) {
        const h = history[id];
        if (!h) return 0;
        const days = (Date.now() - h.t) / 86400000;
        const recency = days < 1 ? 4 : days < 7 ? 2 : days < 30 ? 1 : 0.5;
        return h.n * recency;
    }

    function remember(id) {
        const h = Object.assign({}, history);
        h[id] = { n: (h[id]?.n ?? 0) + 1, t: Date.now() };
        history = h;
        save(h);
    }

    function rememberRun(cmd) {
        const h = Object.assign({}, history);
        h.__runs = [cmd].concat((h.__runs ?? []).filter(c => c !== cmd)).slice(0, 30);
        history = h;
        save(h);
    }

    function save(h) {
        saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
                            "sh", JSON.stringify(h), Config.launcherHistory];
        saveProc.running = true;
    }

    Process { id: saveProc }

    FileView {
        path: Config.launcherHistory
        printErrors: false
        onLoaded: { try { root.history = JSON.parse(text()); } catch (e) {} }
    }

    // ── Setup: installed / missing status ────────────────────────────
    property var setupStatus: ({})
    property int statusTick: 0

    function refreshStatus() {
        const checks = LauncherSections.checksFor("setup");
        if (checks.length === 0) return;
        const script = checks.map(c =>
            'if ' + c.cmd + '; then echo "' + c.id + '|ok"; else echo "' + c.id + '|missing"; fi'
        ).join("\n");
        statusProc.command = ["sh", "-c", script];
        statusProc.running = true;
    }

    Process {
        id: statusProc
        stdout: StdioCollector {
            onStreamFinished: {
                const s = {};
                for (const line of text.split("\n")) {
                    const p = line.split("|");
                    if (p.length === 2) s[p[0]] = p[1];
                }
                root.setupStatus = s;
                root.statusTick++;
            }
        }
    }

    // ── Containers: discover Distrobox environments and their GUI apps ─
    property var containers: []
    property var containerApps: []

    function stopContainer(name) {
        if (containerStopProc.running) return;
        const safeName = String(name).replace(/[^A-Za-z0-9._-]/g, "_");
        containerStopName = String(name);
        const log = Config.home + "/.cache/quickshell/container-logs/" + safeName + "-stop.log";
        containerStopProc.command = [Config.containerStopScript, containerStopName, log];
        containerStopProc.running = true;
    }

    Process {
        id: containerStopProc
        onExited: root.refreshContainers()
    }
    property string containerStopName: ""

    function refreshContainers() {
        containerProc.command = ["sh", "-c",
            "podman ps -a --format '{{.Names}}|{{.Status}}|{{.Image}}' 2>/dev/null || true"];
        containerProc.running = true;
    }

    // Uses real .desktop data inside running containers; never guesses from
    // the package list. Only scans containers that are actually up.
    function refreshContainerApps() {
        const script = [
            'podman ps --format "{{.Names}}" 2>/dev/null | while read -r c; do',
            '  for f in $(podman exec "$c" ls /usr/share/applications/*.desktop 2>/dev/null); do',
            '    n=$(podman exec "$c" grep -m1 "^Name=" "$f" 2>/dev/null | cut -d= -f2-)',
            '    e=$(podman exec "$c" grep -m1 "^Exec=" "$f" 2>/dev/null | cut -d= -f2- | cut -d" " -f1)',
            '    [ -n "$n" ] && [ -n "$e" ] && echo "$c|$n|$e|$(basename "$f")"',
            '  done',
            'done'
        ].join("\n");
        containerAppProc.command = ["sh", "-c", script];
        containerAppProc.running = true;
    }

    Process {
        id: containerProc
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    if (line.trim() === "") continue;
                    const p = line.split("|");
                    out.push({
                        name: p[0] ?? "",
                        status: p[1] ?? "",
                        image: p.slice(2).join("|"),
                        running: /^Up/i.test(p[1] ?? "")
                    });
                }
                root.containers = out;
            }
        }
    }

    Process {
        id: containerAppProc
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const p = line.split("|");
                    if (p.length < 4) continue;
                    out.push({ container: p[0], name: p[1], exec: p[2], file: p[3] });
                }
                root.containerApps = out;
            }
        }
    }

    // ── File search (async) ──────────────────────────────────────────
    property var files: []
    property string fileQuery: ""

    function findFiles(q) {
        fileQuery = q.trim();
        if (fileQuery.length < 2) { files = []; return; }
        fileTimer.restart();
    }

    Timer {
        id: fileTimer
        interval: 180
        onTriggered: {
            if (fileProc.running) fileProc.running = false;
            fileProc.command = ["sh", "-c",
                'cd "$HOME" && if command -v fd >/dev/null; then fd -i -H --max-results 60 --exclude .git --exclude .cache -- "$1"; '
                + 'else find . -maxdepth 5 -not -path "*/.*" -iname "*$1*" 2>/dev/null | head -n 60 | sed "s|^\\./||"; fi',
                "sh", root.fileQuery];
            fileProc.running = true;
        }
    }

    Process {
        id: fileProc
        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(l => l !== "")
        }
    }

    function iconFor(appId) {
        const e = DesktopEntries.heuristicLookup ? DesktopEntries.heuristicLookup(appId) : DesktopEntries.byId(appId);
        return Quickshell.iconPath(e?.icon ?? appId, true);
    }

    function shq(s) { return "'" + String(s ?? "").replace(/'/g, "'\\''") + "'"; }

    function containerShellCommand(name) {
        const markerName = String(name).replace(/[^A-Za-z0-9._-]/g, "_");
        const script = [
            'marker="$HOME/.cache/quickshell/distrobox-zsh/' + markerName + '.done"',
            'mkdir -p "$(dirname "$marker")"',
            'if [ ! -e "$marker" ]; then',
            '  as_root() { if [ "$(id -u)" -eq 0 ]; then "$@"; elif command -v sudo >/dev/null 2>&1; then sudo "$@"; elif command -v doas >/dev/null 2>&1; then doas "$@"; else return 1; fi; }',
            '  if ! command -v zsh >/dev/null 2>&1; then',
            '    if command -v apt-get >/dev/null 2>&1; then as_root apt-get update && as_root apt-get install -y zsh',
            '    elif command -v dnf >/dev/null 2>&1; then as_root dnf install -y zsh',
            '    elif command -v pacman >/dev/null 2>&1; then as_root pacman -S --noconfirm zsh',
            '    elif command -v zypper >/dev/null 2>&1; then as_root zypper --non-interactive install zsh',
            '    elif command -v apk >/dev/null 2>&1; then as_root apk add zsh',
            '    else echo "No supported package manager found to install zsh." >&2; fi',
            '  fi',
            '  if command -v zsh >/dev/null 2>&1; then',
            '    zsh_path=$(command -v zsh); user=${USER:-$(id -un)}',
            '    if command -v usermod >/dev/null 2>&1; then as_root usermod -s "$zsh_path" "$user" || { command -v chsh >/dev/null 2>&1 && chsh -s "$zsh_path" "$user"; }',
            '    elif command -v chsh >/dev/null 2>&1; then chsh -s "$zsh_path" "$user"',
            '    fi',
            '    login_shell=$(getent passwd "$user" 2>/dev/null | cut -d: -f7)',
            '    [ -n "$login_shell" ] || login_shell=$(awk -F: -v user="$user" \'$1 == user {print $7; exit}\' /etc/passwd)',
            '    [ "$login_shell" = "$zsh_path" ] && touch "$marker"',
            '  fi',
            'fi',
            'if command -v zsh >/dev/null 2>&1; then exec zsh -l; fi',
            'echo "zsh is unavailable; opening bash instead." >&2',
            'exec bash -l'
        ].join("\n");
        return "distrobox enter " + shq(name) + " -- sh -lc " + shq(script);
    }

    function containerUpdateCommand(name) {
        const script = 'exec "$HOME/.config/quickshell/shell/bin/container-update"';
        return "distrobox enter " + shq(name) + " -- bash -lc " + shq(script);
    }

    // ── Fuzzy scoring ────────────────────────────────────────────────
    // 0 = no match. Higher is better: exact > prefix > word start > substring > in-order letters.
    function score(hay, q) {
        if (!hay) return 0;
        hay = String(hay).toLowerCase();
        q = String(q).toLowerCase().trim();
        if (!q) return 0;
        if (hay === q) return 120;
        // Do not penalize a useful, descriptive app title for being longer.
        if (hay.startsWith(q)) return 100;
        const words = hay.split(/[\s\-_.]+/);
        if (words.includes(q)) return 92;
        if (words.some(w => w.startsWith(q))) return 80;
        if (words.length > 1 && words.map(w => w[0]).join("").startsWith(q)) return 55;
        const idx = hay.indexOf(q);
        if (idx >= 0) return 50 - Math.min(20, idx);
        let i = 0, run = 0, best = 0;
        for (const ch of hay) {
            if (ch === q[i]) { i++; run++; best = Math.max(best, run); if (i === q.length) break; }
            else run = 0;
        }
        return i === q.length ? 10 + best * 3 : 0;
    }

    // ── Session actions (also reachable from System / global search) ──
    readonly property var actions: [
        { name: "Lock", icon: Icons.lock, cmd: Config.lockCommand, danger: false, keys: "screen quickshell" },
        { name: "Suspend", icon: Icons.suspend, cmd: ["systemctl", "suspend"], danger: false, keys: "sleep" },
        { name: "Log out", icon: Icons.logout, cmd: ["hyprctl", "dispatch", "exit"], danger: true, keys: "logout exit quit hyprland" },
        { name: "Restart", icon: Icons.reboot, cmd: ["systemctl", "reboot"], danger: true, keys: "reboot" },
        { name: "Shut down", icon: Icons.power, cmd: ["systemctl", "poweroff"], danger: true, keys: "shutdown poweroff off" }
    ]

    // ── Calculator ───────────────────────────────────────────────────
    // Small recursive-descent parser: + - * / % ^ and parentheses. No eval.
    function calc(expr) {
        const src = expr.replace(/^=\s*/, "").replace(/×/g, "*").replace(/÷/g, "/").replace(/,/g, ".").replace(/\s+/g, "");
        if (src === "" || !/^[0-9+\-*/%^().]+$/.test(src) || !/\d/.test(src)) return null;
        let i = 0;
        const peek = () => src[i];
        function primary() {
            if (peek() === "(") { i++; const v = sum(); if (peek() !== ")") throw 0; i++; return v; }
            const m = /^\d*\.?\d+/.exec(src.slice(i));
            if (!m) throw 0;
            i += m[0].length;
            return parseFloat(m[0]);
        }
        function unary() { if (peek() === "-") { i++; return -unary(); } if (peek() === "+") { i++; return unary(); } return primary(); }
        function power() { const b = unary(); if (peek() === "^") { i++; return Math.pow(b, power()); } return b; }
        function product() {
            let v = power();
            while ("*/%".includes(peek() ?? "x")) { const op = src[i++]; const r = power(); v = op === "*" ? v * r : op === "/" ? v / r : v % r; }
            return v;
        }
        function sum() {
            let v = product();
            while ("+-".includes(peek() ?? "x")) { const op = src[i++]; const r = product(); v = op === "+" ? v + r : v - r; }
            return v;
        }
        try {
            const v = sum();
            if (i !== src.length || !isFinite(v)) return null;
            return Math.round(v * 1e10) / 1e10;
        } catch (e) {
            return null;
        }
    }

    // ── Dynamic section items ────────────────────────────────────────
    // Desktop entry parsing and icon resolution are stable between app
    // catalogue changes; keep them out of the per-keystroke search path.
    readonly property var appCatalogue: DesktopEntries.applications.values
            // Flea exception removed: the app is disabled in this flake.
            // .filter(a => !a.noDisplay && !(String(a.id).toLowerCase().replace(".desktop", "") === "com.thisisgm.flea" || String(a.name).toLowerCase() === "flea"))
            .filter(a => !a.noDisplay)
            .map(a => ({
                id: "app:" + a.id,
                title: a.name,
                appId: String(a.id ?? "").replace(/\.desktop$/i, ""),
                isApp: true,
                sub: a.genericName || a.comment || "",
                icon: Quickshell.iconPath(a.icon, true),
                glyph: String.fromCodePoint(0xF03D6),
                keys: (a.keywords ?? []).join(" ") + " " + a.id,
                hint: "app",
                desktopId: a.id,
                run: { type: "app", entry: a }
            }));

    function appItems() { return appCatalogue; }

    function containerItems(grouped = true) {
        const out = [];
        const icon = Icons.g(0xF4B7);                       // oct-container
        for (const c of containers) {
            const image = (c.image.split("/").pop() ?? "").split(":")[0];
            const status = c.running ? "Running" : "Stopped";
            if (!grouped) {
                out.push({
                    id: "box:" + c.name,
                    title: c.name,
                    sub: status + (image ? "  ·  " + image : ""),
                    glyph: icon,
                    keys: c.name + " " + c.image + " distrobox podman " + status,
                    hint: "enter",
                    run: { type: "terminal", cmd: containerShellCommand(c.name) }
                });
                continue;
            }
            const restart = c.running
                ? ["sh", "-c", "distrobox stop " + shq(c.name) + " && distrobox enter " + shq(c.name) + " -- true"]
                : ["distrobox", "enter", c.name, "--", "true"];
            const actions = [
                { title: "Restart", enabled: true,
                  run: { type: "cmd", cmd: restart } },
                { title: "Stop", enabled: c.running,
                  run: { type: "containerStop", name: c.name } },
                { title: "Update", enabled: true,
                  run: { type: "popupTerminal", cmd: containerUpdateCommand(c.name) } }
            ];
            const cardHeight = 52 + 60;
            out.push({
                id: "box:" + c.name,
                title: c.name,
                sub: status + (image ? "  ·  " + image : ""),
                glyph: icon, keys: c.name + " " + c.image + " distrobox podman " + status,
                hint: "enter",
                containerHeader: true,
                containerCardMember: true,
                containerCardHeight: cardHeight,
                rowHeight: 52,
                run: { type: "terminal", cmd: containerShellCommand(c.name) }
            });
            out.push({
                id: "boxActions:" + c.name,
                title: c.name + " actions",
                sub: "Restart, stop or update " + c.name,
                keys: "restart stop start update upgrade " + c.name + " container",
                containerCardMember: true,
                containerActionStrip: true,
                containerActions: actions,
                rowHeight: 68,
                run: actions[0].run
            });
        }
        if (grouped) out.push({
                id: "boxOtherOptions",
                title: "Other options",
                keys: "container options list create prune help",
                containerOptionsLabel: true,
                rowHeight: 32
            });
        return out;
    }

    // Live device/section rows (Network, Sound, Power…). Kept in a separate
    // singleton so this engine stays small.
    function liveItems(id) {
        switch (id) {
        case "control":          return LauncherControls.controlItems();
        case "control-layout":   return LauncherControls.layoutItems();
        case "dev-profile":      return LauncherControls.profileItems();
        case "dev-network":      return LauncherControls.networkItems();
        case "dev-bluetooth":    return LauncherControls.bluetoothItems();
        case "dev-sound":        return LauncherControls.soundItems();
        case "dev-display":      return LauncherControls.displayItems();
        case "sys-notifications": return LauncherControls.notificationItems();
        case "sys-clipboard":    return LauncherControls.clipboardItems();
        case "sys-keybinds":     return LauncherControls.keybindItems();
        case "power":            return LauncherControls.powerItems();
        case "style-appearance": return LauncherControls.appearanceItems();
        case "appearance-opacity": return LauncherControls.opacityItems();
        case "appearance-border": return LauncherControls.borderItems();
        case "appearance-panels": return LauncherControls.panelItems();
        case "appearance-dock-settings": return LauncherControls.dockSettingItems();
        case "appearance-panel-settings": return LauncherControls.panelSettingItems();
        case "appearance-animations": return LauncherControls.animationItems();
        default: return [];
        }
    }

    // ── Top-level menu (one row per category) ────────────────────────
    function sectionMenuItems() {
        return rootSections.map(s => ({
            kind: "menu",
            title: s.label,
            sub: s.sub,
            glyph: s.glyph,
            hint: s.num,
            run: { type: "enterSection", id: s.id }
        }));
    }

    // ── Section search ───────────────────────────────────────────────
    function sectionResults(id, q, flattenContainers = false) {
        const sec = sections.find(s => s.id === id);
        if (!sec) return [];
        let items = sec.items.slice();
        if (id === "apps") items = appItems().concat(items);
        if (id === "containers") items = containerItems(!flattenContainers).concat(items);
        items = liveItems(id).concat(items);

        const out = [];
        for (const it of items) {
            const titleScore = score(it.title, q);
            const appIdentityScore = it.isApp
                ? Math.max(titleScore, score(it.appId, q))
                : 0;
            const s = q === "" ? 1 : Math.max(
                titleScore * 1.2,
                score(it.sub, q) * 0.6,
                score(it.keys, q) * 0.8,
                appIdentityScore * 1.2);
            if (s <= 0) continue;
            const boost = it.isApp
                ? Math.min(30, frecency(it.desktopId) * 3)
                : (it.boost ?? 0);
            out.push({
                kind: id,
                title: it.title,
                isApp: it.isApp === true,
                sub: it.sub,
                icon: it.icon ?? "",
                glyph: it.glyph ?? Icons.settings,
                hint: it.hint ?? "",
                configPath: it.configPath ?? "",
                danger: it.danger === true,
                status: it.check ? (setupStatus[it.id] ?? "") : "",
                submenu: it.run?.type === "enterSection",
                section: sec.label,
                // A direct app name/desktop-id match beats a settings row that
                // only mentions that app. Keep fuzzy app matches at normal rank.
                score: s + boost + (appIdentityScore >= 80 ? 32 : 0),
                value: it.value ?? "",
                control: it.control ?? "",
                active: it.active === true,
                keepOpen: it.keepOpen === true,
                containerHeader: it.containerHeader === true,
                containerCardMember: it.containerCardMember === true,
                containerCardHeight: it.containerCardHeight ?? 0,
                containerActionStrip: it.containerActionStrip === true,
                containerActions: it.containerActions ?? [],
                containerOptionsLabel: it.containerOptionsLabel === true,
                rowHeight: it.rowHeight ?? 50,
                adjust: typeof it.adjust === "function" ? it.adjust : null,
                run: it.run
            });
        }
        // Keep the catalogue order for menus; sort by relevance only while searching.
        if (q !== "")
            out.sort((x, y) => y.score - x.score
                || Number(y.isApp === true) - Number(x.isApp === true)
                || x.title.localeCompare(y.title));
        return out.slice(0, 60);
    }

    // ── Global search across every section ───────────────────────────
    function globalSearch(text) {
        const q = text.toLowerCase();
        const out = [];

        const v = calc(text);
        if (v !== null && (text.startsWith("=") || /[+\-*/^%]/.test(text)))
            out.push({ kind: "calc", title: String(v), sub: text.replace(/^=\s*/, "") + "  ·  Enter to copy",
                       glyph: String.fromCodePoint(0xF00EC), hint: "=", section: "Tools",
                       score: 1000, run: { type: "copy", text: String(v) } });

        for (const sec of sections) {
            for (const r of sectionResults(sec.id, q, sec.id === "containers")) {
                r.score *= 0.92;                 // section-local matches win when browsing
                out.push(r);
            }
        }
        for (const a of actions) {
            const s = Math.max(score(a.name, q), score(a.keys, q) * 0.8);
            const alreadyListed = out.some(r => r.title.toLowerCase() === a.name.toLowerCase()
                && r.run?.type === "cmd" && JSON.stringify(r.run.cmd) === JSON.stringify(a.cmd));
            if (s > 0 && !alreadyListed) out.push({ kind: "power", title: a.name,
                                  sub: a.danger ? "Press Enter twice to confirm" : "Session",
                                  glyph: a.icon, hint: "power", danger: a.danger, section: "Session",
                                  score: s * 0.85, run: { type: "cmd", cmd: a.cmd } });
        }

        out.sort((x, y) => y.score - x.score
            || Number(y.isApp === true) - Number(x.isApp === true)
            || x.title.localeCompare(y.title));
        return out.slice(0, 50);
    }

    // ── Search entry point ───────────────────────────────────────────
    // Each result: { kind, title, sub, icon (path) | glyph, hint, danger,
    //                section, status, run: { type, ... } }
    function search(raw) {
        const text = raw.trim();
        const q = text.toLowerCase();
        void statusTick;                 // keep status results reactive
        void liveTick;                   // keep live controls reactive

        if (q.startsWith(":clip")) return clipResults(text.slice(5).trim().toLowerCase());
        if (q.startsWith(":wall")) return [{
            kind: "wall", section: "Wallpapers", title: "Open wallpaper picker",
            sub: "Choose a wallpaper in the full-screen picker",
            glyph: Icons.image, hint: "picker",
            run: { type: "stylePicker", mode: "wallpaper" }
        }];
        if (q.startsWith(":file")) return fileResults();
        if (q.startsWith(":win"))  return windowResults(text.slice(4).trim().toLowerCase());
        if (text.startsWith(">")) {
            const cmd = text.slice(1).trim();
            return cmd === "" ? [] : [{ kind: "run", title: cmd, sub: "Run in background",
                                        glyph: String.fromCodePoint(0xF018D), hint: "shell", section: "Command",
                                        run: { type: "shell", cmd: cmd } }];
        }
        if (text.startsWith("?")) {
            const s = text.slice(1).trim();
            return s === "" ? [] : [{ kind: "web", title: s, sub: "Search the web",
                                      glyph: String.fromCodePoint(0xF059F), hint: "web", section: "Web",
                                      run: { type: "url", url: Config.launcherSearchUrl + encodeURIComponent(s) } }];
        }
        if (q === "") return drilled ? sectionResults(section, "") : sectionMenuItems();
        return globalSearch(text);
    }

    function runResults(text) {
        const q = text.toLowerCase();
        const out = [];
        if (text !== "")
            out.push({ kind: "run", title: text, sub: "Run", glyph: String.fromCodePoint(0xF018D), hint: "run",
                       run: { type: "shell", cmd: text } });
        for (const c of (history.__runs ?? []))
            if (c !== text && (q === "" || c.toLowerCase().includes(q)))
                out.push({ kind: "run", title: c, sub: "Recent", glyph: String.fromCodePoint(0xF02DA), hint: "recent",
                           run: { type: "shell", cmd: c } });
        return out;
    }

    function fileResults() {
        return files.map(f => {
            const name = f.replace(/\/$/, "").split("/").pop();
            const dir = f.slice(0, f.length - name.length).replace(/\/$/, "");
            const isDir = f.endsWith("/");
            return {
                kind: "file", title: name, sub: "~/" + dir, section: "Files",
                glyph: isDir ? String.fromCodePoint(0xF024B) : String.fromCodePoint(0xF0214),
                hint: isDir ? "folder" : "file",
                run: { type: "url", url: "file://" + Config.home + "/" + f }
            };
        });
    }

    function windowResults(q) {
        return ToplevelManager.toplevels.values
            .filter(t => q === "" || (t.title + " " + t.appId).toLowerCase().includes(q))
            .map(t => ({
                kind: "window", title: t.title || t.appId, sub: t.appId, section: "Windows",
                icon: iconFor(t.appId), glyph: String.fromCodePoint(0xF05B0), hint: "window",
                run: { type: "window", toplevel: t }
            }));
    }

    function clipResults(q) {
        return Clipboard.items
            .filter(i => q === "" || (i.image ? "image " + i.meta : i.text).toLowerCase().includes(q))
            .slice(0, 40)
            .map(i => ({
                kind: "clip", section: "Clipboard",
                title: i.image ? "Image" : i.text.replace(/\s+/g, " ").slice(0, 120),
                sub: i.image ? i.meta : "Enter to copy",
                icon: i.image ? i.thumb : "", glyph: Icons.clipboard, hint: "clip",
                run: { type: "clip", item: i }
            }));
    }

    // ── Run ──────────────────────────────────────────────────────────
    signal pageRequested(string name)

    function run(r) {
        const x = r.run;

        // Navigating into a section is not an action: keep the launcher open.
        if (x.type === "enterSection") { enterSection(x.id); return; }
        if (x.type === "section") { enterSection(x.section); return; }

        switch (x.type) {
        case "app":
            if (x.entry) {
                remember(x.entry.id);
                x.entry.execute();
            }
            break;
        case "copy":
            Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", x.text]);
            break;
        case "page":
            pageRequested(x.page.toLowerCase());
            break;
        case "cmd":
            Quickshell.execDetached(x.cmd);
            break;
        case "editor":
            openConfig(x.path);
            break;
        case "containerStop":
            stopContainer(x.name);
            break;
        case "shell":
            rememberRun(x.cmd);
            Quickshell.execDetached(["sh", "-c", x.cmd]);
            break;
        case "terminal":
            Quickshell.execDetached(Config.terminal.concat(["sh", "-c", x.cmd]));
            break;
        case "plainTerminal":
            Quickshell.execDetached(Config.plainTerminal);
            break;
        case "popupTerminal":
            Quickshell.execDetached(Config.popupTerminal.concat(["sh", "-c", x.cmd]));
            break;
        case "stylePicker":
            Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "stylepicker", x.mode]);
            break;
        case "tui":
            // fzpac runs in a floating, centered kitty and closes when done.
            Quickshell.execDetached(Config.tuiTerminal.concat([Config.fzpac, x.mode]));
            break;
        case "hyprSet":
            for (const v of (x.values ?? [{ key: x.key, value: x.value }])) Hypr.set(v.key, v.value);
            break;
        case "hyprToggle":
            Hypr.set(x.key, !Hypr[x.key]);
            break;
        case "barNext":
            BarState.next();
            break;
        case "barSet":
            BarState.set(x.name);
            break;
        case "appearanceReset":
            Hypr.set("gapsIn", 0);
            Hypr.set("gapsOut", 0);
            Hypr.set("borderSize", 0);
            Hypr.set("rounding", 0);
            Hypr.set("blur", false);
            Hypr.set("animations", true);
            break;
        case "callback":
            if (typeof x.fn === "function") x.fn();
            break;
        case "kuroApply":
            Kuro.apply();
            break;
        case "window":
            x.toplevel.activate();
            break;
        case "url":
            Quickshell.execDetached(["xdg-open", x.url]);
            break;
        case "clip":
            Clipboard.copy(x.item);
            break;
        }
        if (r.keepOpen !== true) open = false;
    }

    function openConfig(path) {
        if (!path) return;
        Quickshell.execDetached(Config.terminal.concat(["hx", path]));
    }
}
