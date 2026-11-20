pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config

// Notification daemon (replaces swaync). Quickshell owns
// org.freedesktop.Notifications, so swaync / mako / dunst must be disabled.
//
//   list      : all notifications (newest first), for the notification center
//   popups    : ListModel { nid } currently shown as popups
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
    property var times: ({})                      // id -> Date received
    property alias popups: popupModel

    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: list.length

    // Grouped by app, with the group containing the newest notification first
    readonly property var groups: {
        const map = {};
        const order = [];
        for (const n of list) {
            const key = n.appName || "Unknown";
            if (!map[key]) { map[key] = { app: key, icon: n.appIcon, items: [] }; order.push(key); }
            map[key].items.push(n);
        }
        return order.map(k => map[k]);
    }

    // Legacy API kept so the bar & other pages need few changes
    function refresh() {}
    function toggle() { dnd = !dnd; saveDnd(); }

    function find(id) {
        return server.trackedNotifications.values.find(n => n.id === id) ?? null;
    }

    function hidePopup(id) {
        for (let i = popupModel.count - 1; i >= 0; i--)
            if (popupModel.get(i).nid === id) popupModel.remove(i);
    }

    function dismiss(n) { if (n) n.dismiss(); }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss();
        popupModel.clear();
    }

    function invoke(n, action) {
        action.invoke();
        if (!n.resident) n.dismiss();
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
        if (a) invoke(n, a); else hidePopup(n.id);
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

    ListModel { id: popupModel }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const t = Object.assign({}, root.times);
            t[n.id] = new Date();
            root.times = t;

            n.closed.connect(() => root.hidePopup(n.id));

            const critical = n.urgency === NotificationUrgency.Critical;
            if ((root.dnd || root.centerOpen) && !critical) return;

            root.arrived(n);
            if (root.islandHandles && !critical) return;

            root.hidePopup(n.id);                  // notification being replaced (replaces-id)
            popupModel.insert(0, { nid: n.id });
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

    FileView {
        path: Config.notifStateFile
        printErrors: false
        onLoaded: root.dnd = text().trim() === "1"
    }
}
