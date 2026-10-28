pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.config
import qs.services
import qs.modules.controlcenter
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    anchors.fill: parent

    property string librarySearch: ""
    property string youtubeSearch: ""
    property bool youtubeMusicMode: false
    readonly property var onlinePlayer: Players.list.find(p => /mpv/i.test(p.identity || "")) ?? null
    readonly property var player: onlinePlayer
    readonly property bool useMpris: youtubeMusicMode && onlinePlayer !== null
    readonly property bool waitingOnline: youtubeMusicMode && onlinePlayer === null
    readonly property string currentTitle: waitingOnline ? (YouTubeMusic.selectedTitle || qsTr("YouTube Music"))
        : useMpris ? (player.trackTitle || YouTubeMusic.selectedTitle || qsTr("Nothing playing"))
        : (Mpd.title || qsTr("Nothing playing"))
    readonly property string currentArtist: waitingOnline ? (YouTubeMusic.selectedArtist || qsTr("Search YouTube Music to start playback"))
        : useMpris ? (player.trackArtist || YouTubeMusic.selectedArtist || qsTr("Choose something to play"))
        : Mpd.title ? Mpd.artist : qsTr("Choose a track from your library")
    readonly property real duration: useMpris ? player.length : (waitingOnline ? 0 : Mpd.duration)
    readonly property real position: useMpris ? player.position : (waitingOnline ? 0 : Mpd.elapsed)
    readonly property var filteredLibrary: {
        if (!Mpd.library || Mpd.library.length === 0)
            return [];
        const search = librarySearch.toLowerCase();
        const result = [];
        const limit = 200;
        for (let i = 0; i < Mpd.library.length && result.length < limit; i++) {
            const track = Mpd.library[i];
            const text = `${track.title || ""} ${track.artist || ""} ${track.path || ""}`.toLowerCase();
            if (search === "" || text.includes(search))
                result.push(track);
        }
        return result;
    }
    readonly property var visibleTracks: youtubeMusicMode ? YouTubeMusic.results : filteredLibrary

    function formatTime(seconds: real): string {
        const total = Math.max(0, Math.floor(seconds));
        return `${Math.floor(total / 60)}:${(total % 60).toString().padStart(2, "0")}`;
    }

    function seekToX(x: real, width: real): void {
        if (duration <= 0)
            return;
        const target = Math.max(0, Math.min(1, x / width)) * duration;
        if (useMpris && player?.canSeek && player?.positionSupported)
            player.position = target;
        else if (!youtubeMusicMode && Mpd.available)
            Mpd.seekTo(target);
    }

    function togglePlayback(): void {
        if (youtubeMusicMode && !useMpris)
            return;
        if (useMpris) {
            if (player.canTogglePlaying)
                player.togglePlaying();
        } else {
            Mpd.run(Mpd.playing ? "pause" : "play");
        }
    }

    function previousTrack(): void {
        if (youtubeMusicMode && !useMpris)
            return;
        if (useMpris) {
            if (player.canGoPrevious)
                player.previous();
        } else {
            Mpd.run("prev");
        }
    }

    function nextTrack(): void {
        if (youtubeMusicMode && !useMpris)
            return;
        if (useMpris) {
            if (player.canGoNext)
                player.next();
        } else {
            Mpd.run("next");
        }
    }

    Timer {
        interval: 2000
        running: root.useMpris && (root.player?.isPlaying ?? false)
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.lg
        spacing: Appearance.spacing.lg

        // Searchable local library or public YouTube Music results.
        SectionContainer {
            id: playlistCard
            Layout.fillHeight: true
            Layout.preferredWidth: Math.max(280, parent.width * 0.34)
            Layout.maximumWidth: 420
            Layout.minimumWidth: 250
            alignTop: true
            contentSpacing: Appearance.spacing.md

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.xs
                    StyledText {
                        text: root.youtubeMusicMode ? qsTr("YouTube Music") : qsTr("Library")
                        font.pointSize: Appearance.font.size.titleMedium
                        font.weight: 600
                    }
                    StyledText {
                        text: root.youtubeMusicMode
                            ? (YouTubeMusic.error || (YouTubeMusic.results.length
                                ? qsTr("%1 results").arg(YouTubeMusic.results.length)
                                : qsTr("Search public music without signing in")))
                            : qsTr("%1 tracks available").arg(Mpd.library.length)
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.bodySmall
                    }
                }
                IconButton {
                    type: IconButton.Text
                    icon: "refresh"
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    visible: !root.youtubeMusicMode || root.youtubeSearch.length > 0
                    onClicked: root.youtubeMusicMode
                        ? YouTubeMusic.search(root.youtubeSearch)
                        : Mpd.run("update")
                }
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: Appearance.rounding.medium
                color: Colours.palette.m3surfaceContainerHigh
                visible: true

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.padding.md
                    anchors.rightMargin: Appearance.padding.md
                    MaterialIcon {
                        text: "search"
                        color: Colours.palette.m3onSurfaceVariant
                    }
                    StyledTextField {
                        Layout.fillWidth: true
                        placeholderText: root.youtubeMusicMode
                            ? qsTr("Search YouTube Music")
                            : qsTr("Search your music")
                        text: root.youtubeMusicMode ? root.youtubeSearch : root.librarySearch
                        onTextEdited: text => {
                            if (root.youtubeMusicMode) {
                                root.youtubeSearch = text;
                                searchDebounce.restart();
                            } else {
                                root.librarySearch = text;
                            }
                        }
                    }
                }
            }

            Timer {
                id: searchDebounce
                interval: 450
                repeat: false
                onTriggered: YouTubeMusic.search(root.youtubeSearch)
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.youtubeMusicMode && !root.youtubeSearch && YouTubeMusic.results.length === 0
                text: qsTr("Search for an artist, album, or track. Playback starts without an account.")
                color: Colours.palette.m3onSurfaceVariant
                wrapMode: Text.WordWrap
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.youtubeMusicMode && !!root.youtubeSearch && !YouTubeMusic.error && YouTubeMusic.results.length === 0
                text: qsTr("Searching YouTube Music…")
                color: Colours.palette.m3onSurfaceVariant
                wrapMode: Text.WordWrap
            }
            StyledText {
                Layout.fillWidth: true
                visible: !root.youtubeMusicMode && root.filteredLibrary.length === 0
                text: Mpd.library.length === 0
                    ? qsTr("Add music to ~/Music, then refresh the library.")
                    : qsTr("No tracks match your search.")
                color: Colours.palette.m3onSurfaceVariant
                wrapMode: Text.WordWrap
            }

            ListView {
                id: playlistScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 140
                Layout.preferredHeight: 240
                flickableDirection: Flickable.VerticalFlick
                clip: true
                spacing: Appearance.spacing.xs
                model: root.visibleTracks
                StyledScrollBar.vertical: StyledScrollBar { flickable: playlistScroll }

                delegate: StyledRect {
                    id: trackRow
                    required property var modelData
                    required property int index
                    width: playlistScroll.width
                    height: 62
                    radius: Appearance.rounding.normal
                    color: !root.youtubeMusicMode && Mpd.currentPosition === trackRow.modelData.position
                        ? Colours.palette.m3secondaryContainer
                        : "transparent"

                    StateLayer {
                        radius: Appearance.rounding.normal
                        color: Colours.palette.m3onSurface
                        function onClicked(): void {
                            if (root.youtubeMusicMode)
                                YouTubeMusic.play(trackRow.modelData);
                            else
                                Mpd.playLibraryTrack(trackRow.modelData.path);
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.padding.sm
                        anchors.rightMargin: Appearance.padding.sm
                        spacing: Appearance.spacing.md

                        StyledClippingRect {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: Appearance.rounding.small
                            color: Colours.palette.m3surfaceContainerHigh

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: root.youtubeMusicMode ? "travel_explore" : "music_note"
                                color: Colours.palette.m3primary
                                font.pointSize: Appearance.font.size.titleMedium
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.xs
                            StyledText {
                                Layout.fillWidth: true
                                text: trackRow.modelData.title || qsTr("Untitled track")
                                elide: Text.ElideRight
                                color: !root.youtubeMusicMode && Mpd.currentPosition === trackRow.modelData.position
                                    ? Colours.palette.m3onSecondaryContainer
                                    : Colours.palette.m3onSurface
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: trackRow.modelData.artist || trackRow.modelData.path || qsTr("Unknown artist")
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.bodySmall
                                elide: Text.ElideRight
                            }
                        }

                        MaterialIcon {
                            visible: true
                            text: "play_arrow"
                            color: Colours.palette.m3primary
                        }
                    }
                }
            }

        }

        // Focused now-playing surface with artwork, transport and progress.
        SectionContainer {
            id: nowPlayingCard
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 390
            alignTop: true
            contentSpacing: Appearance.spacing.md

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Listening now")
                    font.pointSize: Appearance.font.size.titleMedium
                    font.weight: 600
                }
                IconButton {
                    type: IconButton.Tonal
                    // Use a standard Material Symbols glyph; folder_music is
                    // missing from the bundled font and renders as text.
                    icon: "library_music"
                    checked: !root.youtubeMusicMode
                    toggle: true
                    Accessible.name: qsTr("Local library")
                    onClicked: root.youtubeMusicMode = false
                }
                IconButton {
                    type: IconButton.Tonal
                    icon: "music_note"
                    checked: root.youtubeMusicMode
                    toggle: true
                    Accessible.name: qsTr("YouTube Music")
                    onClicked: root.youtubeMusicMode = true
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.waitingOnline
                text: YouTubeMusic.selectedTitle
                    ? qsTr("Starting YouTube Music playback…")
                    : qsTr("Choose a result to start playing.")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.bodySmall
                horizontalAlignment: Text.AlignHCenter
            }

            StyledClippingRect {
                id: cover
                readonly property real coverSize: Math.max(176, Math.min(parent.width * 0.58, root.height * 0.38, 292))
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: cover.coverSize
                Layout.preferredHeight: cover.coverSize
                radius: Appearance.rounding.extraLarge
                color: Colours.palette.m3primaryContainer

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0; color: Colours.palette.m3primaryContainer }
                        GradientStop { position: 0.52; color: Colours.palette.m3secondaryContainer }
                        GradientStop { position: 1; color: Colours.palette.m3tertiaryContainer }
                    }
                    visible: !(root.useMpris && root.player?.trackArtUrl) && !(root.youtubeMusicMode && YouTubeMusic.selectedArt)
                }
                MaterialIcon {
                    anchors.centerIn: parent
                    text: "album"
                    color: Colours.palette.m3onPrimaryContainer
                    font.pointSize: cover.width * 0.22
                    visible: !(root.useMpris && root.player?.trackArtUrl) && !(root.youtubeMusicMode && YouTubeMusic.selectedArt)
                }
                StyledClippingRect {
                    anchors.centerIn: parent
                    width: cover.width * 0.72
                    height: width
                    radius: Appearance.rounding.full
                    color: Qt.alpha(Colours.palette.m3onPrimaryContainer, 0.12)
                    visible: !(root.useMpris && root.player?.trackArtUrl) && !(root.youtubeMusicMode && YouTubeMusic.selectedArt)
                    StyledRect {
                        anchors.centerIn: parent
                        width: parent.width * 0.62
                        height: width
                        radius: Appearance.rounding.full
                        color: Qt.alpha(Colours.palette.m3primary, 0.7)
                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "music_note"
                            color: Colours.palette.m3onPrimary
                            font.pointSize: parent.width * 0.42
                        }
                    }
                }
                Image {
                    anchors.fill: parent
                    source: root.useMpris
                        ? (root.player?.trackArtUrl || YouTubeMusic.selectedArt || "")
                        : (root.youtubeMusicMode ? YouTubeMusic.selectedArt : "")
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: width
                    sourceSize.height: height
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.xs
                StyledText {
                    Layout.fillWidth: true
                    text: root.currentTitle
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: Appearance.font.size.headlineSmall
                    font.weight: 600
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.currentArtist
                    horizontalAlignment: Text.AlignHCenter
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.bodyLarge
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: (root.useMpris && !!root.player?.trackAlbum) || (!root.youtubeMusicMode && !!Mpd.album)
                    text: root.useMpris ? (root.player?.trackAlbum || "") : (root.youtubeMusicMode ? "" : Mpd.album)
                    horizontalAlignment: Text.AlignHCenter
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.bodySmall
                    elide: Text.ElideRight
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.xs

                Item {
                    id: waveform
                    Layout.fillWidth: true
                    Layout.maximumWidth: 240
                    Layout.alignment: Qt.AlignHCenter
                    implicitHeight: 40
                    enabled: root.duration > 0 && (root.useMpris
                        ? ((root.player?.canSeek ?? false) && (root.player?.positionSupported ?? false))
                        : (!root.youtubeMusicMode && Mpd.available))

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 2
                        anchors.rightMargin: 2
                        spacing: 1
                        Repeater {
                            model: 64
                            delegate: Rectangle {
                                required property int index
                                readonly property real amplitude: 0.14
                                    + Math.abs(Math.sin(index * 12.9898 + 0.7) * Math.cos(index * 4.1414 + 0.2)) * 0.86
                                width: Math.max(1.5, (waveform.width - 4 - 63) / 64)
                                height: Math.max(5, waveform.height * amplitude)
                                anchors.verticalCenter: parent.verticalCenter
                                radius: width / 2
                                color: (x + width / 2) <= waveform.width * Math.max(0, Math.min(1, root.position / Math.max(root.duration, 1)))
                                    ? Colours.palette.m3primary
                                    : Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.42)
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: waveform.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => root.seekToX(mouse.x, width)
                        onPositionChanged: mouse => {
                            if (pressed)
                                root.seekToX(mouse.x, width);
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { text: root.formatTime(root.position); color: Colours.palette.m3onSurfaceVariant; font.pointSize: Appearance.font.size.bodySmall }
                    Item { Layout.fillWidth: true }
                    StyledText { text: `-${root.formatTime(Math.max(0, root.duration - root.position))}`; color: Colours.palette.m3onSurfaceVariant; font.pointSize: Appearance.font.size.bodySmall }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Appearance.spacing.md

                IconButton {
                    type: IconButton.Text
                    icon: "shuffle"
                    checked: Mpd.random
                    toggle: true
                    disabled: root.youtubeMusicMode || !Mpd.available
                    onClicked: Mpd.run("random")
                }

                IconButton {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 52
                    type: IconButton.Tonal
                    icon: "skip_previous"
                    disabled: root.useMpris ? !(root.player?.canGoPrevious ?? false) : root.youtubeMusicMode || !Mpd.available
                    onClicked: root.previousTrack()
                }
                IconButton {
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 68
                    type: IconButton.Filled
                    icon: (root.useMpris ? (root.player?.isPlaying ?? false) : Mpd.playing) ? "pause" : "play_arrow"
                    disabled: root.useMpris ? !(root.player?.canTogglePlaying ?? false) : root.youtubeMusicMode || !Mpd.available
                    onClicked: root.togglePlayback()
                }
                IconButton {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 52
                    type: IconButton.Tonal
                    icon: "skip_next"
                    disabled: root.useMpris ? !(root.player?.canGoNext ?? false) : root.youtubeMusicMode || !Mpd.available
                    onClicked: root.nextTrack()
                }

                IconButton {
                    type: IconButton.Text
                    icon: "repeat"
                    checked: Mpd.repeat
                    toggle: true
                    disabled: root.youtubeMusicMode || !Mpd.available
                    onClicked: Mpd.run("repeat")
                }
            }

        }
    }

}
