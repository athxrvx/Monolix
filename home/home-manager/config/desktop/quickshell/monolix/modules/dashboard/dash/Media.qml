import qs.components
import qs.components.misc
import qs.services
import qs.config
import qs.utils
import Monolix.Services
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    readonly property bool useMpd: !Players.active && Mpd.available && !!Mpd.title
    readonly property bool hasMedia: !!Players.active || useMpd
    readonly property bool currentPlaying: useMpd ? Mpd.playing : (Players.active?.isPlaying ?? false)
    readonly property string currentTitle: useMpd ? Mpd.title : (Players.active?.trackTitle || qsTr("No media"))
    readonly property string currentAlbum: useMpd ? Mpd.album : (Players.active?.trackAlbum || qsTr("Unknown album"))
    readonly property string currentArtist: useMpd ? Mpd.artist : (Players.active?.trackArtist || qsTr("Unknown artist"))
    property real playerProgress: {
        const length = root.useMpd ? Mpd.duration : (Players.active?.length ?? 0);
        const position = root.useMpd ? Mpd.elapsed : (Players.active?.position ?? 0);
        return length > 0 ? position / length : 0;
    }

    function previousTrack(): void {
        if (useMpd)
            Mpd.run("prev");
        else
            Players.active?.previous();
    }

    function toggleTrack(): void {
        if (useMpd)
            Mpd.run(Mpd.playing ? "pause" : "play");
        else
            Players.active?.togglePlaying();
    }

    function nextTrack(): void {
        if (useMpd)
            Mpd.run("next");
        else
            Players.active?.next();
    }

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Config.dashboard.sizes.mediaWidth

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
        service: BeatTracker
    }

    Shape {
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            strokeWidth: Config.dashboard.sizes.mediaProgressThickness
            capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

            PathAngleArc {
                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: (cover.width + Config.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.spacing.sm
                radiusY: (cover.height + Config.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.spacing.sm
                startAngle: -90 - Config.dashboard.sizes.mediaProgressSweep / 2
                sweepAngle: Config.dashboard.sizes.mediaProgressSweep
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Colours.palette.m3primary
            strokeWidth: Config.dashboard.sizes.mediaProgressThickness
            capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

            PathAngleArc {
                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: (cover.width + Config.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.spacing.sm
                radiusY: (cover.height + Config.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.spacing.sm
                startAngle: -90 - Config.dashboard.sizes.mediaProgressSweep / 2
                sweepAngle: Config.dashboard.sizes.mediaProgressSweep * root.playerProgress
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }
    }

    StyledClippingRect {
        id: cover

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.padding.xl + Config.dashboard.sizes.mediaProgressThickness + Appearance.spacing.sm

        implicitHeight: width
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

    StyledText {
        id: title

        anchors.top: cover.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.spacing.lg

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: root.currentTitle
        color: root.hasMedia ? Colours.palette.m3primary : Colours.palette.m3onSurface
        font.pointSize: Appearance.font.size.bodyMedium

        width: parent.implicitWidth - Appearance.padding.xl * 2
        elide: Text.ElideRight
    }

    StyledText {
        id: album

        anchors.top: title.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.spacing.sm

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: root.currentAlbum
        color: Colours.palette.m3outline
        font.pointSize: Appearance.font.size.labelLarge

        width: parent.implicitWidth - Appearance.padding.xl * 2
        elide: Text.ElideRight
    }

    StyledText {
        id: artist

        anchors.top: album.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.spacing.sm

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: root.currentArtist
        color: root.hasMedia ? Colours.palette.m3secondary : Colours.palette.m3outline

        width: parent.implicitWidth - Appearance.padding.xl * 2
        elide: Text.ElideRight
    }

    Row {
        id: controls

        anchors.top: artist.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.spacing.md

        spacing: Appearance.spacing.sm

        Control {
            icon: "skip_previous"
            canUse: root.useMpd ? !!Mpd.title : (Players.active?.canGoPrevious ?? false)

            function onClicked(): void {
                root.previousTrack();
            }
        }

        Control {
            icon: root.currentPlaying ? "pause" : "play_arrow"
            canUse: root.useMpd ? Mpd.available : (Players.active?.canTogglePlaying ?? false)

            function onClicked(): void {
                root.toggleTrack();
            }
        }

        Control {
            icon: "skip_next"
            canUse: root.useMpd ? !!Mpd.title : (Players.active?.canGoNext ?? false)

            function onClicked(): void {
                root.nextTrack();
            }
        }
    }

    AnimatedImage {
        id: bongocat

        anchors.top: controls.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Appearance.spacing.sm
        anchors.bottomMargin: Appearance.padding.xl
        anchors.margins: Appearance.padding.xl * 2

        playing: root.currentPlaying
        speed: BeatTracker.bpm / 300
        source: Paths.absolutePath(Config.paths.mediaGif)
        asynchronous: true
        fillMode: AnimatedImage.PreserveAspectFit
    }

    component Control: StyledRect {
        id: control

        required property string icon
        required property bool canUse
        function onClicked(): void {
        }

        implicitWidth: Math.max(icon.implicitHeight, icon.implicitHeight) + Appearance.padding.xs
        implicitHeight: implicitWidth

        StateLayer {
            disabled: !control.canUse
            radius: Appearance.rounding.full

            function onClicked(): void {
                control.onClicked();
            }
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            anchors.verticalCenterOffset: font.pointSize * 0.05

            animate: true
            text: control.icon
            color: control.canUse ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font.pointSize: Appearance.font.size.titleMedium
        }
    }
}
