// MPD-backed Kuro music library, queue, and playback window.
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import qs.config
import qs.components
import qs.services

FloatingWindow {
    id: root

    title: "Kuro Music"
    visible: false
    implicitWidth: 1120
    implicitHeight: 740
    color: Theme.bg
    property real seekPreview: -1
    property real volumePreview: -1
    property string inputMode: "NORMAL"
    property string activeInput: ""
    property string selectionPane: "LIBRARY"

    function moveSelection(delta) {
        const inQueue = selectionPane === "QUEUE";
        const view = inQueue ? queueView : libraryView;
        const count = inQueue ? Music.queue.length
            : Music.page === "playlists" ? Music.playlists.length : Music.filteredLibrary.length;
        if (count < 1) return;
        view.currentIndex = Math.max(0, Math.min(count - 1, view.currentIndex + delta));
        view.positionViewAtIndex(view.currentIndex, ListView.Contain);
    }
    function playSelection() {
        if (selectionPane === "QUEUE") {
            if (queueView.currentIndex >= 0 && queueView.currentIndex < Music.queue.length)
                Music.playQueue(queueView.currentIndex);
        } else if (Music.page === "playlists") {
            if (libraryView.currentIndex >= 0 && libraryView.currentIndex < Music.playlists.length)
                Music.playPlaylist(Music.playlists[libraryView.currentIndex]);
        } else if (libraryView.currentIndex >= 0 && libraryView.currentIndex < Music.filteredLibrary.length) {
            Music.playTrack(Music.filteredLibrary[libraryView.currentIndex]);
        }
    }
    function enqueueSelection() {
        if (selectionPane === "LIBRARY" && Music.page === "library" && libraryView.currentIndex >= 0 && libraryView.currentIndex < Music.filteredLibrary.length)
            Music.enqueueTrack(Music.filteredLibrary[libraryView.currentIndex]);
    }
    function removeQueueSelection() {
        if (selectionPane === "QUEUE" && queueView.currentIndex >= 0 && queueView.currentIndex < Music.queue.length)
            Music.removeQueue(queueView.currentIndex);
    }

    function toggle() { visible = !visible; }
    function openWindow() { visible = true; }
    function setSeek(mouseX, width) {
        if (Music.duration <= 0) return;
        seekPreview = Math.max(0, Math.min(1, mouseX / Math.max(1, width)));
    }
    function commitSeek() {
        if (seekPreview >= 0) Music.seekTo(seekPreview * Music.duration);
        seekPreview = -1;
    }
    function setVolumePreview(mouseX, width) {
        volumePreview = Math.round(Math.max(0, Math.min(1, mouseX / Math.max(1, width))) * 100);
    }
    function commitVolume() {
        if (volumePreview >= 0) Music.setVolume(volumePreview);
        volumePreview = -1;
    }

    onVisibleChanged: {
        Music.active = visible;
        if (visible) {
            Music.refresh();
            if (Music.autoScanOnOpen) Music.updateDatabase();
        }
    }

    FolderDialog {
        id: musicFolderDialog
        title: "Add a music folder"
        // The GTK native chooser crashes in this GTK3-themed Qt session.
        options: FolderDialog.DontUseNativeDialog
        currentFolder: "file://" + Config.home
        onAccepted: {
            const path = decodeURIComponent(selectedFolder.toString().replace(/^file:\/\//, ""));
            Music.addMusicFolder(path);
        }
    }

    Shortcut { sequence: "j"; enabled: root.visible && root.inputMode === "NORMAL"; onActivated: root.moveSelection(1) }
    Shortcut { sequence: "k"; enabled: root.visible && root.inputMode === "NORMAL"; onActivated: root.moveSelection(-1) }
    Shortcut { sequence: "Return"; enabled: root.visible && root.inputMode === "NORMAL"; onActivated: root.playSelection() }
    Shortcut { sequence: "Enter"; enabled: root.visible && root.inputMode === "NORMAL"; onActivated: root.playSelection() }
    Shortcut { sequence: "a"; enabled: root.visible && root.inputMode === "NORMAL"; onActivated: root.enqueueSelection() }
    Shortcut { sequence: "d"; enabled: root.visible && root.inputMode === "NORMAL"; onActivated: root.removeQueueSelection() }
    Shortcut { sequence: "q"; enabled: root.visible && root.inputMode === "NORMAL"; onActivated: root.selectionPane = root.selectionPane === "LIBRARY" ? "QUEUE" : "LIBRARY" }
    Shortcut { sequence: "Space"; enabled: root.visible && root.inputMode === "NORMAL"; onActivated: Music.togglePlayback() }
    Shortcut { sequence: "h"; enabled: root.visible && root.inputMode === "NORMAL"; onActivated: Music.previous() }
    Shortcut { sequence: "l"; enabled: root.visible && root.inputMode === "NORMAL"; onActivated: Music.next() }
    Shortcut { sequence: "/"; enabled: root.visible && root.inputMode === "NORMAL" && Music.page === "library"; onActivated: searchInput.forceActiveFocus() }
    Shortcut {
        sequence: "Escape"
        enabled: root.visible && root.inputMode === "INSERT"
        onActivated: {
            if (root.activeInput === "search") searchInput.text = "";
            searchInput.focus = false;
            playlistName.focus = false;
            root.activeInput = "";
            root.inputMode = "NORMAL";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: Theme.surface
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 14
                spacing: 6

                TextButton {
                    text: "LIBRARY"
                    sharp: true
                    flat: true
                    primary: Music.page === "library"
                    onClicked: Music.page = "library"
                }
                TextButton {
                    text: "PLAYLISTS"
                    sharp: true
                    flat: true
                    primary: Music.page === "playlists"
                    onClicked: { Music.page = "playlists"; Music.refresh(); }
                }
                TextButton {
                    text: "SETTINGS"
                    sharp: true
                    flat: true
                    primary: Music.page === "settings"
                    onClicked: Music.page = "settings"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Music.state === "playing" ? "PLAYING" : Music.state === "paused" ? "PAUSED" : "MPD PLAYER"
                    color: Music.state === "playing" ? Theme.accent : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }
                TextButton { text: Icons.refresh; sharp: true; onClicked: Music.refresh() }
                TextButton { text: Icons.close; sharp: true; onClicked: root.visible = false }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bg

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.preferredWidth: 192
                    Layout.fillHeight: true
                    color: Theme.bgAlt

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        Text {
                            text: "COLLECTION"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.letterSpacing: 1.5
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            color: "transparent"
                            border.color: "transparent"
                            Rectangle { width: 2; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; color: Theme.accent; visible: Music.page === "library" }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                spacing: 8
                                Text { text: Icons.music; color: Music.page === "library" ? Theme.accent : Theme.muted; font.family: Theme.iconFont; font.pixelSize: 15 }
                                Text { Layout.fillWidth: true; text: "All tracks"; color: Theme.text; font.family: Theme.font; font.pixelSize: 12 }
                                Text { text: String(Music.library.length); color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                            }
                            TapHandler { onTapped: Music.page = "library" }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            color: "transparent"
                            border.color: "transparent"
                            Rectangle { width: 2; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; color: Theme.accent; visible: Music.page === "playlists" }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                spacing: 8
                                Text { text: Icons.music; color: Theme.muted; font.family: Theme.iconFont; font.pixelSize: 15 }
                                Text { Layout.fillWidth: true; text: "Playlists"; color: Theme.text; font.family: Theme.font; font.pixelSize: 12 }
                                Text { text: String(Music.playlists.length); color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                            }
                            TapHandler { onTapped: { Music.page = "playlists"; Music.refresh(); } }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            color: "transparent"
                            border.color: "transparent"
                            Rectangle { width: 2; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; color: Theme.accent; visible: Music.page === "settings" }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                spacing: 8
                                Text { text: "⚙"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 15 }
                                Text { Layout.fillWidth: true; text: "Settings"; color: Theme.text; font.family: Theme.font; font.pixelSize: 12 }
                            }
                            TapHandler { onTapped: Music.page = "settings" }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
                        Item { Layout.fillHeight: true }
                        Text {
                            Layout.fillWidth: true
                            text: Music.library.length === 0 ? "Add music to ~/Music" : Music.library.length + " tracks indexed"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 10
                            wrapMode: Text.Wrap
                        }
                        TextButton {
                            Layout.fillWidth: true
                            sharp: true
                            flat: true
                            text: Music.databaseState !== "" ? "Scanning…" : "Update library"
                            enabled: Music.databaseState === ""
                            onClicked: Music.updateDatabase()
                        }
                    }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.border }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 16
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: Music.page !== "settings"
                        spacing: 6
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: Music.page === "library" ? "Library" : "Playlists"
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 18
                                font.bold: true
                            }
                            Rectangle {
                                visible: Music.page === "library"
                                Layout.preferredWidth: 200
                                Layout.preferredHeight: 30
                                color: Theme.surface
                                border.color: searchInput.activeFocus ? Theme.accent : Theme.border
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    Text { text: Icons.search; color: Theme.muted; font.family: Theme.iconFont; font.pixelSize: 14 }
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        TextInput {
                                            id: searchInput
                                            anchors.fill: parent
                                            color: Theme.text
                                            selectionColor: Theme.selectionBg
                                            selectedTextColor: Theme.selectionFg
                                            font.family: Theme.font
                                            font.pixelSize: 11
                                            verticalAlignment: TextInput.AlignVCenter
                                            onTextChanged: Music.search = text
                                            onActiveFocusChanged: {
                                                root.inputMode = activeFocus ? "INSERT" : "NORMAL";
                                                root.activeInput = activeFocus ? "search" : "";
                                            }
                                        }
                                        Text {
                                            anchors.fill: searchInput
                                            visible: searchInput.text === ""
                                            text: "Search tracks"
                                            color: Theme.muted
                                            font.family: Theme.font
                                            font.pixelSize: 11
                                            verticalAlignment: Text.AlignVCenter
                                            enabled: false
                                        }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            visible: Music.page === "playlists"
                            Layout.fillWidth: true
                            Text { text: "Save current queue"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.preferredWidth: 170
                                Layout.preferredHeight: 30
                                color: Theme.surface
                                border.color: playlistName.activeFocus ? Theme.accent : Theme.border
                                TextInput {
                                    id: playlistName
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    color: Theme.text
                                    selectionColor: Theme.selectionBg
                                    selectedTextColor: Theme.selectionFg
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    onAccepted: {
                                        Music.savePlaylist(text);
                                        text = "";
                                        focus = false;
                                    }
                                    onActiveFocusChanged: {
                                        root.inputMode = activeFocus ? "INSERT" : "NORMAL";
                                        root.activeInput = activeFocus ? "playlist" : "";
                                    }
                                    Text {
                                        anchors.fill: parent
                                        visible: playlistName.text === ""
                                        text: "Playlist name"
                                        color: Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        verticalAlignment: Text.AlignVCenter
                                        enabled: false
                                    }
                                }
                            }
                            TextButton {
                                text: "SAVE"
                                sharp: true
                                enabled: playlistName.text.trim() !== "" && Music.queue.length > 0
                                onClicked: { Music.savePlaylist(playlistName.text); playlistName.text = ""; }
                            }
                        }
                    }

                    ColumnLayout {
                        visible: Music.page !== "settings"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        spacing: 5
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: Music.currentTitle !== "" ? Music.currentTitle : "Kuro Music"
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            Text {
                                text: Music.currentArtist
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: Music.currentAlbum || "MPD library"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9; elide: Text.ElideRight }
                            Item { Layout.fillWidth: true }
                            Text { text: Music.state === "playing" ? "● PLAYING" : Music.state.toUpperCase(); color: Music.state === "playing" ? Theme.accent : Theme.muted; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1 }
                        }
                    }

                    RowLayout {
                        visible: Music.page !== "settings"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        spacing: 8
                        Text { Layout.preferredWidth: 32; text: "#"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                        Text { Layout.fillWidth: true; text: Music.page === "library" ? "TITLE / ARTIST" : "PLAYLIST"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1 }
                        Text { visible: Music.page === "library"; Layout.preferredWidth: 110; text: "ALBUM"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1 }
                        Text { visible: Music.page === "library"; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight; text: "LENGTH"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9 }
                    }

                    ListView {
                        id: libraryView
                        visible: Music.page !== "settings"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 1
                        boundsBehavior: Flickable.DragAndOvershootBounds
                        flickDeceleration: 700
                        maximumFlickVelocity: 5000
                        currentIndex: count > 0 ? 0 : -1
                        model: Music.page === "library" ? Music.filteredLibrary : Music.playlists
                        delegate: Rectangle {
                            id: trackRow
                            required property var modelData
                            required property int index
                            width: libraryView.width
                            height: 36
                            color: index === libraryView.currentIndex || hovered ? Theme.surface2 : "transparent"
                            property bool hovered: false
                            Rectangle {
                                width: 2
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                color: Theme.accent
                                visible: index === libraryView.currentIndex || hovered
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8
                                Text { Layout.preferredWidth: 24; text: String(trackRow.index + 1).padStart(2, "0"); color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        Layout.fillWidth: true
                                        text: Music.page === "library" ? (trackRow.modelData.title ?? trackRow.modelData) : trackRow.modelData
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        visible: Music.page === "library"
                                        Layout.fillWidth: true
                                        text: trackRow.modelData.artist ?? "Unknown artist"
                                        color: Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }
                                }
                                Text {
                                    Layout.preferredWidth: 110
                                    visible: Music.page === "library"
                                    text: trackRow.modelData.album ?? ""
                                    color: Theme.subtext
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.preferredWidth: 42
                                    horizontalAlignment: Text.AlignRight
                                    text: Music.page === "library" ? Music.formatTime(trackRow.modelData.duration) : ""
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 9
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onEntered: trackRow.hovered = true
                                onExited: trackRow.hovered = false
                                onClicked: mouse => {
                                    libraryView.currentIndex = trackRow.index;
                                    if (Music.page === "playlists" && mouse.button === Qt.RightButton) Music.deletePlaylist(trackRow.modelData);
                                    else if (Music.page === "playlists") Music.playPlaylist(trackRow.modelData);
                                    else if (mouse.button === Qt.RightButton) Music.enqueueTrack(trackRow.modelData);
                                    else Music.playTrack(trackRow.modelData);
                                }
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: Music.page !== "settings" && (Music.error !== "" || (Music.page === "library" && Music.library.length === 0) || (Music.page === "playlists" && Music.playlists.length === 0))
                        text: Music.error !== "" ? Music.error : Music.databaseState !== "" ? Music.databaseState : Music.page === "playlists" ? "No playlists yet. Save the current queue using the field above." : "No indexed music. Put audio files in ~/Music and choose Update library."
                        color: Music.error !== "" ? Theme.danger : Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Flickable {
                        visible: Music.page === "settings"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        boundsBehavior: Flickable.DragAndOvershootBounds
                        flickDeceleration: 700
                        maximumFlickVelocity: 5000
                        contentHeight: settingsContent.implicitHeight

                        ColumnLayout {
                        id: settingsContent
                        x: 0
                        width: parent.width
                        spacing: 12

                        Text { text: "Player settings"; color: Theme.text; font.family: Theme.font; font.pixelSize: 18; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: "Playback and library options for your MPD player. Changes are saved automatically."
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 54
                            spacing: 16
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text { text: "Scan library when opened"; color: Theme.text; font.family: Theme.font; font.pixelSize: 11 }
                                Text { text: "Ask MPD to index new and changed files whenever the player opens."; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9; wrapMode: Text.Wrap }
                            }
                            Switch {
                                checked: Music.autoScanOnOpen
                                onToggled: Music.setAutoScan(!Music.autoScanOnOpen)
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 54
                            spacing: 16
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text { text: "Single track mode"; color: Theme.text; font.family: Theme.font; font.pixelSize: 11 }
                                Text { text: "Stop after the current track instead of advancing."; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9; wrapMode: Text.Wrap }
                            }
                            Switch { checked: Music.single; onToggled: Music.toggleSingle() }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 54
                            spacing: 16
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text { text: "Consume queue"; color: Theme.text; font.family: Theme.font; font.pixelSize: 11 }
                                Text { text: "Remove tracks from the queue after they finish playing."; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9; wrapMode: Text.Wrap }
                            }
                            Switch { checked: Music.consume; onToggled: Music.toggleConsume() }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
                        Text { text: "MUSIC FOLDER"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1 }
                        Text {
                            text: Music.musicDirectory
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 11
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            TextButton { text: "OPEN FOLDER"; sharp: true; onClicked: Music.openMusicFolder() }
                            TextButton { text: "ADD MUSIC FOLDER"; sharp: true; onClicked: musicFolderDialog.open() }
                        }
                        Text {
                            text: "IMPORTED FOLDERS"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 9
                            font.letterSpacing: 1
                        }
                        ListView {
                            id: importedFolderList
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(120, contentHeight)
                            visible: Music.importedFolders.length > 0
                            clip: true
                            model: Music.importedFolders
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: importedFolderList.width
                                height: 32
                                color: index % 2 === 0 ? Theme.surface : "transparent"
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 4
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                            + " · " + modelData.path
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                    TextButton { text: "REMOVE"; sharp: true; onClicked: Music.removeMusicFolder(modelData.name) }
                                }
                            }
                        }
                        Text {
                            visible: Music.importedFolders.length === 0
                            text: "No extra folders added."
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 9
                        }
                        Text {
                            visible: Music.folderStatus !== ""
                            text: Music.folderStatus
                            color: Music.folderStatus.startsWith("Added") || Music.folderStatus.startsWith("Removed") || Music.folderStatus.startsWith("Adding") || Music.folderStatus.startsWith("Removing") ? Theme.accent : Theme.danger
                            font.family: Theme.font
                            font.pixelSize: 9
                            wrapMode: Text.Wrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Extra folders are linked into Imported Folders; removing one only removes that link, never the original files."
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 9
                            wrapMode: Text.Wrap
                        }
                        Text {
                            text: "Audio output · MPD / PipeWire"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 9
                        }
                        Item { Layout.fillHeight: true }
                        }
                    }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.border }

                Rectangle {
                    Layout.preferredWidth: 252
                    Layout.fillHeight: true
                    color: Theme.bgAlt

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: "UP NEXT"; color: Theme.text; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 1 }
                            Text { text: String(Music.queue.length); color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                            TextButton { text: "CLEAR"; sharp: true; enabled: Music.queue.length > 0; onClicked: Music.clearQueue() }
                        }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
                        ListView {
                            id: queueView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 2
                            boundsBehavior: Flickable.DragAndOvershootBounds
                            flickDeceleration: 700
                            maximumFlickVelocity: 5000
                            currentIndex: count > 0 ? 0 : -1
                            model: Music.queue
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: queueView.width
                                height: 42
                                color: root.selectionPane === "QUEUE" && index === queueView.currentIndex ? Theme.surface2 : "transparent"
                                border.width: 0
                                Rectangle {
                                    width: 2
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    color: Theme.accent
                                    visible: root.selectionPane === "QUEUE" && index === queueView.currentIndex
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 8
                                    Text { text: String(index + 1).padStart(2, "0"); color: Theme.muted; font.family: Theme.font; font.pixelSize: 9 }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { Layout.fillWidth: true; text: modelData.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 10; elide: Text.ElideRight }
                                        Text { Layout.fillWidth: true; text: modelData.artist; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9; elide: Text.ElideRight }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: mouse => {
                                        queueView.currentIndex = index;
                                        if (mouse.button === Qt.RightButton) Music.removeQueue(index);
                                        else Music.playQueue(index);
                                    }
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: Music.queue.length === 0
                            text: "Right-click a library track to add it here. Left-click to play; right-click to remove."
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 10
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 104
            color: Theme.surface
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: 5

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18
                    Text { text: root.inputMode; color: Theme.accent; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1 }
                    Rectangle { width: 1; height: 12; color: Theme.border }
                    Text {
                        Layout.fillWidth: true
                        text: root.inputMode === "INSERT"
                            ? root.activeInput === "search" ? "TYPE TO SEARCH  ·  ESC CLEAR" : "TYPE PLAYLIST NAME  ·  ESC NORMAL"
                            : "J/K MOVE  ·  ENTER PLAY  ·  A QUEUE  ·  D REMOVE  ·  Q PANE  ·  / SEARCH  ·  SPACE PAUSE  ·  H/L TRACK"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                    Text { text: root.selectionPane; color: Theme.text; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1 }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    TextButton { text: "|◀"; sharp: true; onClicked: Music.previous() }
                    TextButton { text: Music.state === "playing" ? "Ⅱ" : "▶"; primary: true; sharp: true; onClicked: Music.togglePlayback() }
                    TextButton { text: "▶|"; sharp: true; onClicked: Music.next() }
                    TextButton { text: "■"; sharp: true; onClicked: Music.stop() }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { Layout.fillWidth: true; text: Music.currentTitle || "Nothing playing"; color: Theme.text; font.family: Theme.font; font.pixelSize: 11; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: [Music.currentArtist, Music.currentAlbum].filter(Boolean).join(" · ") || "MPD · local library"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9; elide: Text.ElideRight }
                    }
                    TextButton { text: Music.random ? "⤨ ON" : "⤨"; sharp: true; primary: Music.random; onClicked: Music.toggleRandom() }
                    TextButton { text: Music.repeat ? "↻ ON" : "↻"; sharp: true; primary: Music.repeat; onClicked: Music.toggleRepeat() }
                    Text { text: "VOL"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9 }
                    Text { text: String(root.volumePreview >= 0 ? root.volumePreview : Music.volume) + "%"; color: Theme.text; font.family: Theme.font; font.pixelSize: 10 }
                    Item {
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 20
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 3; color: Theme.border }
                        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: parent.width * (root.volumePreview >= 0 ? root.volumePreview : Music.volume) / 100; height: 3; color: Theme.accent }
                        Rectangle { width: 8; height: 12; y: 4; x: Math.max(0, parent.width * (root.volumePreview >= 0 ? root.volumePreview : Music.volume) / 100 - 4); color: Theme.text }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: mouse => root.setVolumePreview(mouse.x, width)
                            onPositionChanged: mouse => { if (pressed) root.setVolumePreview(mouse.x, width); }
                            onReleased: root.commitVolume()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight; text: Music.formatTime(root.seekPreview >= 0 ? root.seekPreview * Music.duration : Music.elapsed); color: Theme.muted; font.family: Theme.font; font.pixelSize: 9 }
                    Item {
                        id: seekTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 2; color: Theme.border }
                        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: parent.width * (root.seekPreview >= 0 ? root.seekPreview : Music.duration > 0 ? Music.elapsed / Music.duration : 0); height: 2; color: Theme.accent }
                        Rectangle { width: 8; height: 8; y: 4; x: Math.max(0, parent.width * (root.seekPreview >= 0 ? root.seekPreview : Music.duration > 0 ? Music.elapsed / Music.duration : 0) - 4); color: Theme.accent }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: mouse => root.setSeek(mouse.x, width)
                            onPositionChanged: mouse => { if (pressed) root.setSeek(mouse.x, width); }
                            onReleased: root.commitSeek()
                        }
                    }
                    Text { Layout.preferredWidth: 40; text: Music.formatTime(Music.duration); color: Theme.muted; font.family: Theme.font; font.pixelSize: 9 }
                }
            }
        }
    }
}
