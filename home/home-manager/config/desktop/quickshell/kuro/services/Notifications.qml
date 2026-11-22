pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config

// Notification daemon (replaces swaync). Quickshell owns
// org.freedesktop.Notifications, so swaync / mako / dunst must be disabled.
//
//   list      : immutable notification arrivals (newest first), for the center
//   popups    : ListModel { nid, token } currently shown as popups
//   dnd       : popups hidden (except critical), history still recorded
Singleton {
    id: root

    readonly property string daemon: "quickshell"
    readonly property bool available: true

    property bool dnd: false
    property bool centerOpen: false               // notification panel below the bar

    function toggleCenter() { centerOpen = !centerOpen; }

    // Dynamic island (island/Island.qml) takes over popups while active
    property bool islandHandles: false
    signal arrived(var notification)

    // When the panel opens, visible popups are dismissed (already visible in the panel)
    onCenterOpenChanged: if (centerOpen) popupModel.clear()
    property var times: ({})                      // arrival token -> Date received
    property var entries: []
    property int nextEventToken: 0
    property var latestEventById: ({})
    property bool historyLoaded: false
    property alias popups: popupModel

    onEntriesChanged: if (historyLoaded) historySaveTimer.restart()

    readonly property var list: entries.slice().reverse()
    readonly property int count: list.length

    // Group each event by its resolved app identity. Entries remain separate;
    // replacing a notification ID never overwrites its previous history row.
    readonly property var groups: {
        const map = new Map();
        for (const n of list) {
            const info = sourceInfo(n);
            const key = info.name || n.appName || "Unknown app";
            if (!map.has(key)) {
                map.set(key, {
                    key,
                    app: key,
                    icon: info.icon || "",
                    appIcon: n.appIcon || "",
                    items: [],
                    latestToken: n.timeKey
                });
            }
            const group = map.get(key);
            group.items.push(n);
            if (n.timeKey > group.latestToken) {
                group.latestToken = n.timeKey;
                group.icon = info.icon || group.icon;
                group.appIcon = n.appIcon || group.appIcon;
            }
        }
        return Array.from(map.values()).sort((a, b) => b.latestToken - a.latestToken);
    }
    property var expandedGroups: ({})

    function isGroupExpanded(key) { return expandedGroups[String(key)] === true; }
    function toggleGroup(key) {
        const next = Object.assign({}, expandedGroups);
        const name = String(key);
        if (next[name]) delete next[name];
        else next[name] = true;
        expandedGroups = next;
    }
    function clearGroup(group) {
        if (!group) return;
        for (const entry of group.items.slice()) dismiss(entry);
        const next = Object.assign({}, expandedGroups);
        delete next[String(group.key)];
        expandedGroups = next;
    }

    // Legacy API kept so the bar & other pages need few changes
    function refresh() {}
    function toggle() { dnd = !dnd; saveDnd(); }

    function find(id) {
        return server.trackedNotifications.values.find(n => n.id === id) ?? null;
    }

    function snapshot(n) {
        const token = ++nextEventToken;
        const snapshot = {
            id: n.id,
            timeKey: token,
            eventToken: token,
            appName: n.appName,
            desktopEntry: n.desktopEntry,
            appIcon: n.appIcon,
            image: n.image,
            summary: n.summary,
            body: n.body,
            urgency: n.urgency,
            expireTimeout: n.expireTimeout,
            transient: n.transient,
            resident: n.resident,
            hasInlineReply: n.hasInlineReply,
            inlineReplyPlaceholder: n.inlineReplyPlaceholder,
            hints: n.hints,
            actions: actionsOf(n),
            _notification: n
        };
        const updated = entries.slice();
        updated.push(snapshot);
        entries = updated;
        const dates = Object.assign({}, times);
        dates[token] = new Date();
        times = dates;
        const latest = Object.assign({}, latestEventById);
        latest[n.id] = token;
        latestEventById = latest;
        return snapshot;
    }

    function restoreHistory(raw) {
        let saved = [];
        try { saved = JSON.parse(raw || "[]"); } catch (e) { saved = []; }
        if (!Array.isArray(saved)) saved = [];

        const known = new Set(entries.map(entry => Number(entry.eventToken)));
        const restored = [];
        const dates = Object.assign({}, times);
        let maxToken = nextEventToken;
        for (const item of saved) {
            const token = Number(item.eventToken ?? item.timeKey);
            if (!Number.isFinite(token) || token <= 0 || known.has(token)) continue;
            const timestamp = Number(item.timestamp) || Date.now();
            const urgency = Number(item.urgency);
            restored.push({
                id: Number(item.id) || 0,
                timeKey: token,
                eventToken: token,
                appName: String(item.appName || "Notification"),
                desktopEntry: String(item.desktopEntry || ""),
                appIcon: String(item.appIcon || ""),
                image: String(item.image || ""),
                summary: String(item.summary || ""),
                body: String(item.body || ""),
                urgency: Number.isFinite(urgency) ? urgency : NotificationUrgency.Normal,
                expireTimeout: 0,
                transient: false,
                resident: false,
                hasInlineReply: false,
                inlineReplyPlaceholder: "",
                hints: ({}),
                actions: [],
                _notification: null
            });
            dates[token] = new Date(timestamp);
            known.add(token);
            maxToken = Math.max(maxToken, token);
        }

        entries = restored.concat(entries).sort((a, b) => a.eventToken - b.eventToken).slice(-500);
        times = dates;
        nextEventToken = maxToken;
        historyLoaded = true;
        historySaveTimer.restart();
    }

    function saveHistory() {
        const data = entries.slice(-500).map(entry => ({
            id: entry.id,
            eventToken: entry.eventToken,
            timestamp: times[entry.eventToken]?.getTime() ?? Date.now(),
            appName: entry.appName,
            desktopEntry: entry.desktopEntry,
            appIcon: entry.appIcon,
            image: entry.image,
            summary: entry.summary,
            body: entry.body,
            urgency: entry.urgency
        }));
        historyProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
            "sh", JSON.stringify(data), Config.notifHistoryFile];
        historyProc.running = true;
    }

    function findEntry(token) {
        return entries.find(entry => entry.eventToken === token) ?? null;
    }

    function hidePopupToken(token) {
        for (let i = popupModel.count - 1; i >= 0; i--)
            if (popupModel.get(i).token === token) popupModel.remove(i);
    }

    function dismiss(n) {
        if (!n) return;
        const notification = n._notification || n;
        if (n.eventToken !== undefined) {
            entries = entries.filter(entry => entry.eventToken !== n.eventToken);
            hidePopupToken(n.eventToken);
            if (latestEventById[n.id] === n.eventToken) notification.dismiss();
        } else {
            notification.dismiss();
        }
    }

    function clearAll() {
        entries = [];
        for (const n of server.trackedNotifications.values.slice()) n.dismiss();
        popupModel.clear();
    }

    function invoke(n, action) {
        action.invoke();
        if (!n.resident) dismiss(n);
    }

    function sendInlineReply(n, text) {
        const reply = String(text ?? "").trim();
        if (!n || !n.hasInlineReply || reply === "") return false;
        (n._notification || n).sendInlineReply(reply);
        if (!n.resident) dismiss(n);
        return true;
    }

    function sourceInfo(n) {
        if (!n) return { name: "Notification", icon: "" };
        const app = String(n.appName || "Notification");
        const desktop = String(n.desktopEntry || "");
        const hints = n.hints || {};
        const browser = /firefox|chrome|chromium|brave|vivaldi|microsoft-edge|msedge/i.test(app + " " + desktop);
        const meta = [
            desktop, app,
            hints["x-kde-origin-name"], hints["x-kde-origin-url"],
            hints["origin"], hints["url"], hints["desktop-entry"],
            browser ? n.summary : ""
        ].filter(Boolean).join(" ").toLowerCase();
        const sites = [
            { test: /whatsapp|wa\.me/, name: "WhatsApp", icon: Icons.whatsapp },
            { test: /youtube|youtu\.be/, name: "YouTube", icon: Icons.youtube },
            { test: /discord/, name: "Discord", icon: Icons.discord },
            { test: /instagram/, name: "Instagram", icon: Icons.instagram },
            { test: /spotify/, name: "Spotify", icon: Icons.spotify },
            { test: /telegram/, name: "Telegram", icon: Icons.telegram },
            { test: /gmail|googlemail/, name: "Gmail", icon: Icons.gmail }
        ];
        for (const site of sites) {
            if (site.test.test(meta) && (browser || site.test.test(app + " " + desktop)))
                return { name: site.name, icon: site.icon };
        }
        return { name: app, icon: "" };
    }

    // list<NotificationAction> -> plain JS array
    function actionsOf(n) {
        const out = [];
        if (!n) return out;
        for (let i = 0; i < n.actions.length; i++) out.push(n.actions[i]);
        return out;
    }

    // "default" action = clicking the notification body
    function activate(n) {
        if (!n) return;
        const a = actionsOf(n).find(x => x.identifier === "default");
        if (a) invoke(n, a); else hidePopupToken(n.eventToken);
    }

    function iconSource(name) {
        if (!name) return "";
        if (name.startsWith("/")) return "file://" + name;
        if (name.includes("://")) return name;
        return Quickshell.iconPath(name, true);
    }

    function ago(id) {
        const t = times[id];
        if (!t) return "";
        const s = Math.floor((Date.now() - t.getTime()) / 1000);
        if (s < 60) return "now";
        if (s < 3600) return Math.floor(s / 60) + "m";
        if (s < 86400) return Math.floor(s / 3600) + "h";
        return Qt.formatDateTime(t, "dd MMM");
    }

    function clockTime(id) {
        const t = times[id];
        return t ? Qt.formatDateTime(t, "hh:mm") : "";
    }

    ListModel { id: popupModel }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        inlineReplySupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const entry = root.snapshot(n);

            n.closed.connect(() => {
                // A replaced ID closes the old server object too. Always drop
                // that event's toast, even though its history snapshot remains.
                root.hidePopupToken(entry.eventToken);
            });

            const critical = n.urgency === NotificationUrgency.Critical;
            if ((root.dnd || root.centerOpen) && !critical) return;

            root.arrived(entry);
            if (root.islandHandles && !critical) return;

            popupModel.insert(0, { nid: n.id, token: entry.eventToken });
            while (popupModel.count > Config.notifMaxPopups) popupModel.remove(popupModel.count - 1);
        }
    }

    // ── DND is saved so it persists after a restart ───────────────────
    function saveDnd() {
        saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
                            "sh", dnd ? "1" : "0", Config.notifStateFile];
        saveProc.running = true;
    }

    Process { id: saveProc }

    Timer {
        id: historySaveTimer
        interval: 350
        repeat: false
        onTriggered: root.saveHistory()
    }

    Process { id: historyProc }

    FileView {
        path: Config.notifHistoryFile
        printErrors: false
        onLoaded: root.restoreHistory(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root.restoreHistory("[]");
            else root.historyLoaded = true;
        }
    }

    FileView {
        path: Config.notifStateFile
        printErrors: false
        onLoaded: root.dnd = text().trim() === "1"
    }
}
