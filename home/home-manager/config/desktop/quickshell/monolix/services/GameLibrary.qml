pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

Singleton {
    id: root

    readonly property string filePath: `${Paths.data}/games.json`
    property list<var> customGames: []
    property string statusText: ""
    property bool ready: false

    function add(name: string, commandLine: string): void {
        const cleanName = name.trim();
        const command = commandLine.trim().split(/\s+/).filter(part => part.length > 0);
        if (!cleanName || command.length === 0) {
            statusText = qsTr("Enter a game name and launch command.");
            return;
        }
        const updated = [...customGames, { id: Date.now().toString(), name: cleanName, command }];
        customGames = updated;
        statusText = qsTr("Added %1 to your library.").arg(cleanName);
        saveProcess.running = true;
    }

    function remove(id: string): void {
        customGames = customGames.filter(game => game.id !== id);
        statusText = qsTr("Game removed from your Monolix library.");
        saveProcess.running = true;
    }

    function launch(game: var): void {
        if (game?.command?.length)
            Quickshell.execDetached(game.command);
    }

    function save(): void {
        if (!ready) {
            statusText = qsTr("Game library is still loading.");
            return;
        }
        fileView.setText(JSON.stringify(customGames, null, 2));
    }

    FileView {
        id: fileView
        path: root.filePath
        watchChanges: true
        onLoaded: {
            root.ready = true;
            try {
                const data = JSON.parse(text());
                root.customGames = Array.isArray(data) ? data.filter(game => game.name && Array.isArray(game.command)) : [];
            } catch (error) {
                console.error("Monolix game library: invalid registry", error);
                root.customGames = [];
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.ready = true;
                root.customGames = [];
                directoryProcess.running = true;
            } else {
                root.statusText = qsTr("Could not read your Monolix game library.");
                console.error("Monolix game library read error:", FileViewError[error] || error);
            }
        }
    }

    Process {
        id: directoryProcess
        command: ["mkdir", "-p", `${Paths.data}`]
        running: false
        onExited: (code) => {
            if (code === 0)
                fileView.setText("[]");
        }
    }

    Process {
        id: saveProcess
        command: ["mkdir", "-p", `${Paths.data}`]
        running: false
        onExited: (code) => {
            if (code === 0)
                root.save();
            else
                root.statusText = qsTr("Could not save your game library.");
        }
    }
}
