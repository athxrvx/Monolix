pragma Singleton

import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string filePath: `${Paths.data}/hub-tasks.json`
    property list<var> tasks: []
    property bool ready: false
    property string statusText: ""
    property string _pendingText: ""
    property bool _createEmptyFile: false

    readonly property int openCount: tasks.filter(task => !task.done).length

    function add(title: string): void {
        const cleanTitle = title.trim();
        if (!cleanTitle) {
            statusText = qsTr("Write a task first.");
            return;
        }
        if (!ready) {
            statusText = qsTr("Your task list is still loading.");
            return;
        }
        tasks = [{ id: Date.now().toString(), title: cleanTitle, done: false }].concat(tasks);
        statusText = qsTr("Task added.");
        save();
    }

    function toggle(id: string): void {
        tasks = tasks.map(task => task.id === id
            ? { id: task.id, title: task.title, done: !task.done }
            : task);
        save();
    }

    function remove(id: string): void {
        tasks = tasks.filter(task => task.id !== id);
        save();
    }

    function clearCompleted(): void {
        tasks = tasks.filter(task => !task.done);
        save();
    }

    function save(): void {
        _pendingText = JSON.stringify(tasks, null, 2);
        mkdirProcess.running = true;
    }

    FileView {
        id: fileView
        path: root.filePath
        watchChanges: true
        onLoaded: {
            root.ready = true;
            try {
                const data = JSON.parse(text());
                root.tasks = Array.isArray(data)
                    ? data.filter(task => task && task.id && task.title).map(task => ({
                        id: String(task.id),
                        title: String(task.title),
                        done: Boolean(task.done)
                    }))
                    : [];
            } catch (error) {
                root.tasks = [];
                root.statusText = qsTr("The saved task list could not be read.");
                console.error("Monolix Hub task list is invalid:", error);
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.ready = true;
                root.tasks = [];
                root._createEmptyFile = true;
                mkdirProcess.running = true;
            } else {
                root.statusText = qsTr("Could not read the saved task list.");
                console.error("Monolix Hub task list read error:", FileViewError[error] || error);
            }
        }
    }

    Process {
        id: mkdirProcess
        command: ["mkdir", "-p", Paths.data]
        running: false
        onExited: code => {
            if (code !== 0) {
                root.statusText = qsTr("Could not create the Monolix data folder.");
                return;
            }
            if (root.ready && root._pendingText.length > 0) {
                fileView.setText(root._pendingText);
                root._pendingText = "";
            } else if (root._createEmptyFile) {
                root._createEmptyFile = false;
                fileView.setText("[]");
            }
        }
    }
}
