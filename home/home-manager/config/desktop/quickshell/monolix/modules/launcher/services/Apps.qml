pragma Singleton

import qs.config
import qs.utils
import qs.modules.music
import qs.modules.hub
import Quickshell
import QtQuick

Searcher {
    id: root

    readonly property var builtInApps: [
        {
            id: "monolix-music",
            name: "Music",
            comment: qsTr("MPD library and YouTube Music search"),
            genericName: qsTr("Music player"),
            icon: "multimedia-player",
            execString: "monolix ipc call music open",
            command: ["monolix", "ipc", "call", "music", "open"],
            categories: ["AudioVideo", "Audio", "Player"],
            keywords: ["music", "mpd", "youtube", "player"],
            runInTerminal: false,
            monolixBuiltin: true
        },
        {
            id: "monolix-hub",
            name: "Monohub",
            comment: qsTr("Wallpapers, game library, and Mono tools"),
            genericName: qsTr("Games and desktop hub"),
            icon: "applications-games",
            execString: "monolix ipc call hub open",
            command: ["monolix", "ipc", "call", "hub", "open"],
            categories: ["Utility", "Game"],
            keywords: ["hub", "games", "wallpapers", "mono", "library"],
            runInTerminal: false,
            monolixBuiltin: true
        }
    ]

    function launch(entry: var): void {
        if (entry?.monolixBuiltin || entry?.id === "monolix-music" || entry?.id === "monolix-hub") {
            // Launcher and settings are already inside the same Monolix
            // process. Open these through the same Component/createObject
            // window-factory pattern used by the Settings window, rather than
            // launching another shell process and hoping its IPC finds us.
            if (entry.id === "monolix-music")
                MusicWindowFactory.create(null);
            else
                HubWindowFactory.create(null);
            return;
        }
        // Keep launched apps outside Monolix's service cgroup. Home Manager
        // activation restarts the shell, and systemd otherwise kills all of
        // its child apps (including Chromium) with it.
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: ["systemd-run", "--user", "--scope", "--collect", "--quiet", "--", ...Config.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            Quickshell.execDetached({
                command: ["systemd-run", "--user", "--scope", "--collect", "--quiet", "--", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
    }

    // Prefer the installed desktop entry when Home Manager has registered it;
    // keep the in-process entry as a fallback so both apps remain available
    // even before the desktop database has refreshed.
    function withBuiltInFallbacks(results: list<var>): list<var> {
        const ids = results.map(entry => entry.id);
        return [...results, ...root.builtInApps.filter(app => !ids.includes(app.id))];
    }

    function search(search: string): list<var> {
        const prefix = Config.launcher.specialPrefix;

        if (search.startsWith(`${prefix}i `)) {
            keys = ["id", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}c `)) {
            keys = ["categories", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}d `)) {
            keys = ["desc", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}e `)) {
            keys = ["execString", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}w `)) {
            keys = ["wmClass", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}g `)) {
            keys = ["genericName", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}k `)) {
            keys = ["keywords", "name"];
            weights = [0.9, 0.1];
        } else {
            keys = ["name"];
            weights = [1];

            if (!search.startsWith(`${prefix}t `)) {
                const results = query(search).map(e => e.modelData);
                return withBuiltInFallbacks(results.filter(app => !root.builtInApps.some(builtin => builtin.id === app.id)))
                    .filter(app => !search.trim() || app.name.toLowerCase().includes(search.trim().toLowerCase()))
                    .sort((a, b) => a.name.localeCompare(b.name));
            }
        }

        const term = search.slice(prefix.length + 2);
        const results = query(term).map(e => e.modelData);
        if (search.startsWith(`${prefix}t `))
            return results.filter(a => a.runInTerminal);
        return withBuiltInFallbacks(results.filter(app => !root.builtInApps.some(builtin => builtin.id === app.id)))
            .filter(app => !term.trim() || keys.some(key => {
                const field = key === "desc" ? "comment" : key === "wmClass" ? "startupClass" : key;
                const value = app[field];
                const text = Array.isArray(value) ? value.join(" ") : String(value ?? "");
                return text.toLowerCase().includes(term.trim().toLowerCase());
            }))
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    function selector(item: var): string {
        return keys.map(k => item[k]).join(" ");
    }

    list: variants.instances
    useFuzzy: Config.launcher.useFuzzy.apps

    Variants {
        id: variants

        model: [...DesktopEntries.applications.values].sort((a, b) => a.name.localeCompare(b.name))

        QtObject {
            required property var modelData
            readonly property string id: modelData.id || ""
            readonly property string name: modelData.name || ""
            readonly property string desc: modelData.comment || ""
            readonly property string execString: modelData.execString || ""
            readonly property string wmClass: modelData.startupClass || ""
            readonly property string genericName: modelData.genericName || ""
            readonly property string categories: (modelData.categories || []).join(" ")
            readonly property string keywords: (modelData.keywords || []).join(" ")
        }
    }
}
