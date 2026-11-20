pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Small persistent todo list used by the calendar popup.
Singleton {
    id: root

    property var items: []
    property bool loaded: false
    property bool tryLegacy: false

    function parse(raw) {
        const source = String(raw ?? "").trim();
        if (source === "") return [];
        // Read the previous JSON format once so existing tasks survive the
        // move to the human-editable Markdown file.
        if (source.startsWith("[")) {
            try { const legacy = JSON.parse(source); return Array.isArray(legacy) ? legacy : []; }
            catch (e) { return []; }
        }
        const out = [];
        source.split("\n").forEach((line, index) => {
            const m = line.match(/^\s*-\s+\[([ xX])\]\s+(\d{4}-\d{2}-\d{2})\s+\|\s+(.*)$/);
            if (m) out.push({ id: "task-" + index, done: m[1].toLowerCase() === "x", date: m[2], title: m[3] });
        });
        return out;
    }

    function markdown() {
        const rows = items.map(i => "- [" + (i.done ? "x" : " ") + "] " + i.date + " | " +
            String(i.title).replace(/[\r\n]+/g, " "));
        return "# Tasks\n\n" + rows.join("\n") + (rows.length ? "\n" : "");
    }

    function keyFor(date) {
        return Qt.formatDate(date, "yyyy-MM-dd");
    }

    function add(title, date) {
        const t = String(title ?? "").replace(/[\r\n]+/g, " ").trim();
        if (t === "") return;
        const entry = {
            id: Date.now() + "-" + Math.floor(Math.random() * 10000),
            title: t,
            date: date || keyFor(new Date()),
            done: false
        };
        items = items.concat([entry]);
        save();
    }

    function remove(id) {
        items = items.filter(i => i.id !== id);
        save();
    }

    function toggle(id) {
        items = items.map(i => i.id === id ? Object.assign({}, i, { done: !i.done }) : i);
        save();
    }

    function forDate(date) {
        const key = typeof date === "string" ? date : keyFor(date);
        return items.filter(i => i.date === key)
                    .sort((a, b) => Number(a.done) - Number(b.done) || a.title.localeCompare(b.title));
    }

    function upcoming(limit) {
        const today = keyFor(new Date());
        return items.filter(i => !i.done && i.date >= today)
                    .sort((a, b) => a.date.localeCompare(b.date) || a.title.localeCompare(b.title))
                    .slice(0, limit ?? 6);
    }

    function save() {
        if (root.loaded) saveTimer.restart();
    }

    Timer {
        id: saveTimer
        interval: 200
        onTriggered: {
            if (!root.loaded) return;
            saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
                                "sh", root.markdown(), Config.todoStateFile];
            saveProc.running = true;
        }
    }

    Process { id: saveProc }

    FileView {
        path: Config.todoStateFile
        printErrors: false
        onLoaded: {
            root.items = root.parse(text());
            root.loaded = true;
        }
        onLoadFailed: root.tryLegacy = true
    }

    // Migrate the previous cache file once, then keep task.md authoritative.
    Loader {
        active: root.tryLegacy
        sourceComponent: Component {
            FileView {
                path: Config.home + "/.cache/quickshell/todos.json"
                printErrors: false
                onLoaded: {
                    root.items = root.parse(text());
                    root.loaded = true;
                    if (root.items.length > 0) root.save();
                }
                onLoadFailed: root.loaded = true
            }
        }
    }
}
