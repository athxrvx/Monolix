pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.components.misc
import qs.components.controls
import qs.services
import qs.utils
import qs.config
import Monolix.Services
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root

    required property PersistentProperties visibilities

    readonly property bool useMpd: !Players.active && Mpd.available && !!Mpd.title
    readonly property bool hasMedia: !!Players.active || useMpd
    readonly property bool currentPlaying: useMpd ? Mpd.playing : (Players.active?.isPlaying ?? false)
    readonly property real currentLength: useMpd ? Mpd.duration : (Players.active?.length ?? 0)
    readonly property real currentPosition: useMpd ? Mpd.elapsed : (Players.active?.position ?? 0)
    readonly property string currentTitle: useMpd ? Mpd.title : (Players.active?.trackTitle || qsTr("No media"))
    readonly property string currentAlbum: useMpd ? Mpd.album : (Players.active?.trackAlbum || qsTr("Unknown album"))
    readonly property string currentArtist: useMpd ? Mpd.artist : (Players.active?.trackArtist || qsTr("Unknown artist"))

    property real playerProgress: {
        return root.currentLength > 0 ? root.currentPosition / root.currentLength : 0;
    }

    function toggleCurrentPlayback(): void {
        if (useMpd)
            Mpd.run(Mpd.playing ? "pause" : "play");
        else if (Players.active?.canTogglePlaying)
            Players.active.togglePlaying();
    }

    function previousTrack(): void {
        if (useMpd)
            Mpd.run("prev");
        else if (Players.active?.canGoPrevious)
            Players.active.previous();
    }

    function nextTrack(): void {
        if (useMpd)
            Mpd.run("next");
        else if (Players.active?.canGoNext)
            Players.active.next();
    }

    function lengthStr(length: int): string {
        if (length < 0)
            return "-1:-1";

        const hours = Math.floor(length / 3600);
        const mins = Math.floor((length % 3600) / 60);
        const secs = Math.floor(length % 60).toString().padStart(2, "0");

        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
        return `${mins}:${secs}`;
    }

    implicitWidth: cover.implicitWidth + Config.dashboard.sizes.mediaVisualiserSize * 2 + details.implicitWidth + details.anchors.leftMargin + bongocat.implicitWidth + bongocat.anchors.leftMargin * 2 + Appearance.padding.xl * 2
    implicitHeight: Math.max(cover.implicitHeight + Config.dashboard.sizes.mediaVisualiserSize * 2, details.implicitHeight, bongocat.implicitHeight) + Appearance.padding.xl * 2

    Behavior on playerProgress {
        Anim {
            duration: Appearance.anim.durations.large
        }
    }

    Timer {
        running: root.useMpd ? Mpd.playing : (Players.active?.isPlaying ?? false)
        interval: Config.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: root.useMpd ? Mpd.refresh() : Players.active?.positionChanged()
    }

    ServiceRef {
        service: Cava.provider
    }

    ServiceRef {
        service: BeatTracker
    }

    Shape {
        id: visualiser

        readonly property real centerX: width / 2
        readonly property real centerY: height / 2
        readonly property real innerX: cover.implicitWidth / 2 + Appearance.spacing.sm
        readonly property real innerY: cover.implicitHeight / 2 + Appearance.spacing.sm
        property color colour: Colours.palette.m3primary

        anchors.fill: cover
        anchors.margins: -Config.dashboard.sizes.mediaVisualiserSize

        asynchronous: true
        preferredRendererType: Shape.CurveRenderer
        data: visualiserBars.instances
    }

    Variants {
        id: visualiserBars

        model: Array.from({
            length: Config.services.visualiserBars
        }, (_, i) => i)

        ShapePath {
            id: visualiserBar

            required property int modelData
            readonly property real value: Math.max(1e-3, Math.min(1, Cava.values[modelData]))

            readonly property real angle: modelData * 2 * Math.PI / Config.services.visualiserBars
            readonly property real magnitude: value * Config.dashboard.sizes.mediaVisualiserSize
            readonly property real cos: Math.cos(angle)
            readonly property real sin: Math.sin(angle)

            capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap
            strokeWidth: 360 / Config.services.visualiserBars - Appearance.spacing.sm / 4
            strokeColor: Colours.palette.m3primary

            startX: visualiser.centerX + (visualiser.innerX + strokeWidth / 2) * cos
            startY: visualiser.centerY + (visualiser.innerY + strokeWidth / 2) * sin

            PathLine {
                x: visualiser.centerX + (visualiser.innerX + visualiserBar.strokeWidth / 2 + visualiserBar.magnitude) * visualiserBar.cos
                y: visualiser.centerY + (visualiser.innerY + visualiserBar.strokeWidth / 2 + visualiserBar.magnitude) * visualiserBar.sin
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }
    }

    StyledClippingRect {
        id: cover

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.xl + Config.dashboard.sizes.mediaVisualiserSize

        implicitWidth: Config.dashboard.sizes.mediaCoverArtSize
        implicitHeight: Config.dashboard.sizes.mediaCoverArtSize

        color: Colours.tPalette.m3surfaceContainerHigh
        radius: Infinity

        MaterialIcon {
            anchors.centerIn: parent

            grade: 200
            text: root.useMpd ? "music_note" : "art_track"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: (parent.width * 0.4) || 1
        }

        Image {
            id: image

            anchors.fill: parent

            source: root.useMpd ? "" : (Players.active?.trackArtUrl ?? "")
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: width
            sourceSize.height: height
        }
    }

    ColumnLayout {
        id: details

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: visualiser.right
        anchors.leftMargin: Appearance.spacing.lg

        spacing: Appearance.spacing.sm

        StyledText {
            id: title

            Layout.fillWidth: true
            Layout.maximumWidth: parent.implicitWidth

            animate: true
            horizontalAlignment: Text.AlignHCenter
            text: root.currentTitle
            color: root.hasMedia ? Colours.palette.m3primary : Colours.palette.m3onSurface
            font.pointSize: Appearance.font.size.bodyMedium
        }

        StyledText {
            id: album

            Layout.fillWidth: true
            Layout.maximumWidth: parent.implicitWidth

            animate: true
            horizontalAlignment: Text.AlignHCenter
            visible: root.hasMedia
            text: root.currentAlbum
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.labelLarge
        }

        StyledText {
            id: artist

            Layout.fillWidth: true
            Layout.maximumWidth: parent.implicitWidth

            animate: true
            horizontalAlignment: Text.AlignHCenter
            text: root.hasMedia ? root.currentArtist : qsTr("Play some music for stuff to show up here!")
            color: root.hasMedia ? Colours.palette.m3secondary : Colours.palette.m3outline
            elide: Text.ElideRight
            wrapMode: root.hasMedia ? Text.NoWrap : Text.WordWrap
        }

        RowLayout {
            id: controls

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Appearance.spacing.sm
            Layout.bottomMargin: Appearance.spacing.md

            spacing: Appearance.spacing.sm

            PlayerControl {
                icon: "skip_previous"
                canUse: root.useMpd ? !!Mpd.title : (Players.active?.canGoPrevious ?? false)

                function onClicked(): void {
                    root.previousTrack();
                }
            }

            StyledRect {
                id: playBtn

                property int fontSize: Appearance.font.size.headlineLarge
                property int padding
                property bool fill: true
                property bool primary
                function onClicked(): void {
                }

                implicitWidth: Math.max(playIcon.implicitWidth, playIcon.implicitHeight) + padding * 2
                implicitHeight: implicitWidth

                radius: root.currentPlaying ? Appearance.rounding.small : implicitHeight / 2 * Math.min(1, Appearance.rounding.scale)
                color: {
                    if (!root.useMpd && !Players.active?.canTogglePlaying)
                        return Qt.alpha(Colours.palette.m3onSurface, 0.1);
                    return root.currentPlaying ? Colours.palette.m3primary : Colours.palette.m3primaryContainer;
                }

                StateLayer {
                    disabled: root.useMpd ? !Mpd.available : !Players.active?.canTogglePlaying
                    color: root.currentPlaying ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer

                    function onClicked(): void {
                        root.toggleCurrentPlayback();
                    }
                }

                MaterialIcon {
                    id: playIcon

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -font.pointSize * 0.02
                    anchors.verticalCenterOffset: font.pointSize * 0.02

                    animate: true
                    fill: 1
                    text: root.currentPlaying ? "pause" : "play_arrow"
                    color: {
                        if (root.useMpd ? !Mpd.available : !Players.active?.canTogglePlaying)
                            return Qt.alpha(Colours.palette.m3onSurface, 0.38);
                        return root.currentPlaying ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer;
                    }
                    font.pointSize: Appearance.font.size.headlineLarge
                }

                Behavior on radius {
                    Anim {}
                }
            }

            PlayerControl {
                icon: "skip_next"
                canUse: root.useMpd ? !!Mpd.title : (Players.active?.canGoNext ?? false)

                function onClicked(): void {
                    root.nextTrack();
                }
            }
        }

        StyledSlider {
            id: slider

            enabled: root.hasMedia && (root.useMpd || (Players.active?.canSeek ?? false))
            implicitWidth: controls.implicitWidth * 1.5
            implicitHeight: Appearance.padding.md * 3

            onMoved: {
                const active = Players.active;
                if (root.useMpd)
                    Mpd.seekTo(value * Mpd.duration);
                else if (active?.canSeek && active?.positionSupported)
                    active.position = value * active.length;
            }

            Binding {
                target: slider
                property: "value"
                value: root.playerProgress
                when: !slider.pressed
            }

            CustomMouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton

                function onWheel(event: WheelEvent) {
                    const active = Players.active;
                    if (!root.useMpd && (!active?.canSeek || !active?.positionSupported))
                        return;

                    event.accepted = true;
                    const delta = event.angleDelta.y > 0 ? 10 : -10; // Time 10 seconds
                    Qt.callLater(() => {
                        if (root.useMpd)
                            Mpd.seekTo(Math.max(0, Math.min(Mpd.duration, Mpd.elapsed + delta)));
                        else
                            active.position = Math.max(0, Math.min(active.length, active.position + delta));
                    });
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: Math.max(position.implicitHeight, length.implicitHeight)

            StyledText {
                id: position

                anchors.left: parent.left

                text: root.lengthStr(root.hasMedia ? root.currentPosition : -1)
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.labelLarge
            }

            StyledText {
                id: length

                anchors.right: parent.right

                text: root.lengthStr(root.hasMedia ? root.currentLength : -1)
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.labelLarge
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.sm

            PlayerControl {
                icon: "flip_to_front"
                canUse: Players.active?.canRaise ?? false
                fontSize: Appearance.font.size.bodyLarge
                padding: Appearance.padding.xs
                fill: false
                color: Colours.tPalette.m3surfaceContainer

                function onClicked(): void {
                    Players.active?.raise();
                    root.visibilities.dashboard = false;
                }
            }

            StyledRect {
                id: playerSelector

                property bool expanded

                Layout.alignment: Qt.AlignVCenter

                implicitWidth: slider.implicitWidth * 0.6
                implicitHeight: currentPlayer.implicitHeight + Appearance.padding.sm * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                z: 1

                StateLayer {
                    disabled: Players.list.length <= 1

                    function onClicked(): void {
                        playerSelector.expanded = !playerSelector.expanded;
                    }
                }

                RowLayout {
                    id: currentPlayer

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.sm

                    PlayerIcon {
                        visible: !!Players.active
                        player: Players.active
                    }
                    MaterialIcon {
                        visible: root.useMpd
                        text: "music_note"
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.maximumWidth: playerSelector.implicitWidth - implicitHeight - parent.spacing - Appearance.padding.md * 2
                        text: Players.active ? Players.getIdentity(Players.active) : root.useMpd ? qsTr("Music · MPD") : qsTr("No players")
                        color: root.hasMedia ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }
                }

                Elevation {
                    anchors.fill: playerSelectorBg
                    radius: playerSelectorBg.radius
                    opacity: playerSelector.expanded ? 1 : 0
                    level: 2

                    Behavior on opacity {
                        Anim {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                        }
                    }
                }

                StyledClippingRect {
                    id: playerSelectorBg

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    implicitWidth: playerSelector.expanded ? playerList.implicitWidth : playerSelector.implicitWidth
                    implicitHeight: playerSelector.expanded ? playerList.implicitHeight : playerSelector.implicitHeight

                    color: Colours.palette.m3secondaryContainer
                    radius: Appearance.rounding.normal
                    opacity: playerSelector.expanded ? 1 : 0

                    ColumnLayout {
                        id: playerList

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom

                        spacing: 0

                        Repeater {
                            model: [...Players.list].sort((a, b) => (a === Players.active) - (b === Players.active))

                            Item {
                                id: player

                                required property MprisPlayer modelData

                                Layout.fillWidth: true
                                Layout.minimumWidth: playerSelector.implicitWidth
                                implicitWidth: playerInner.implicitWidth + Appearance.padding.md * 2
                                implicitHeight: playerInner.implicitHeight + Appearance.padding.sm * 2

                                StateLayer {
                                    disabled: !playerSelector.expanded

                                    function onClicked(): void {
                                        playerSelector.expanded = false;
                                        Players.manualActive = player.modelData;
                                    }
                                }

                                RowLayout {
                                    id: playerInner

                                    anchors.centerIn: parent
                                    spacing: Appearance.spacing.sm

                                    PlayerIcon {
                                        player: player.modelData
                                    }

                                    StyledText {
                                        text: Players.getIdentity(player.modelData)
                                        color: Colours.palette.m3onSecondaryContainer
                                    }
                                }
                            }
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                        }
                    }

                    Behavior on implicitWidth {
                        Anim {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }

                    Behavior on implicitHeight {
                        Anim {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }
                }
            }

            PlayerControl {
                icon: "delete"
                canUse: Players.active?.canQuit ?? false
                fontSize: Appearance.font.size.bodyLarge
                padding: Appearance.padding.xs
                fill: false
                color: Colours.tPalette.m3surfaceContainer

                function onClicked(): void {
                    Players.active?.quit();
                }
            }
        }
    }

    Item {
        id: bongocat

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: details.right
        anchors.leftMargin: Appearance.spacing.lg

        implicitWidth: visualiser.width
        implicitHeight: visualiser.height

        AnimatedImage {
            anchors.centerIn: parent

            width: visualiser.width * 0.75
            height: visualiser.height * 0.75

            playing: Players.active?.isPlaying ?? false
            speed: BeatTracker.bpm / 300
            source: Paths.absolutePath(Config.paths.mediaGif)
            asynchronous: true
            fillMode: AnimatedImage.PreserveAspectFit
        }
    }

    component PlayerIcon: Loader {
        id: loader

        required property MprisPlayer player
        readonly property string icon: Icons.getAppIcon(player?.identity)

        Layout.fillHeight: true
        asynchronous: true
        sourceComponent: !player || icon === "image://icon/" ? fallbackIcon : playerImage

        Component {
            id: playerImage

            IconImage {
                implicitWidth: height
                source: loader.icon
            }
        }

        Component {
            id: fallbackIcon

            MaterialIcon {
                text: loader.player ? "animated_images" : "music_off"
            }
        }
    }

    component PlayerControl: StyledRect {
        id: control

        required property string icon
        required property bool canUse
        property int fontSize: Appearance.font.size.headlineLarge
        property int padding
        property bool fill: true
        function onClicked(): void {
        }

        implicitWidth: Math.max(icon.implicitWidth, icon.implicitHeight) + padding * 2
        implicitHeight: implicitWidth
        radius: Appearance.rounding.full

        StateLayer {
            disabled: !control.canUse
            color: Colours.palette.m3onSurface

            function onClicked(): void {
                control.onClicked();
            }
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -font.pointSize * 0.02
            anchors.verticalCenterOffset: font.pointSize * 0.02

            animate: true
            fill: control.fill ? 1 : 0
            text: control.icon
            color: control.canUse ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font.pointSize: control.fontSize
        }
    }
}
