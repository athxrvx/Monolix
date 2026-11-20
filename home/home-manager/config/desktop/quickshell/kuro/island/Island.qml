// Tide Island-style dynamic island: a floating black pill at the top center,
// its width follows the content and it morphs with spring animations.
//   idle      clock
//   media     track title + equalizer
//   hint      volume / brightness / battery (icon + percent + ring), workspace switch
//   notif     new notification (click = open, right-click = dismiss)
//   expanded  hover / click: full player, or a big clock + date + weather
//
// Appears when the active bar layout has `island: true` (see bar/BarState.qml).

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.config
import qs.services
import qs.bar

Scope {
    id: root

    readonly property var lay: BarState.layout
    readonly property bool active: Config.islandEnabled && BarState.shown && lay.island === true

    // Colors & font: config/IslandStyle.qml

    // ── Media ────────────────────────────────────────────────────────
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool hasMedia: player !== null && (player.trackTitle ?? "") !== ""
    readonly property bool playing: hasMedia && player.isPlaying

    // ── Transient state ───────────────────────────────────────────────
    property string hintIcon: ""
    property string hintText: ""
    property real hintRing: -1           // 0..1 = show ring, -1 = no ring
    property var notif: null
    property bool expanded: false
    property bool pinned: false
    property bool ready: false           // ignore changes right after startup

    readonly property string mode: notif ? "notif"
                                 : hintText !== "" ? "hint"
                                 : expanded ? "expanded"
                                 : hasMedia ? "media" : "idle"

    function hint(icon, text, ring, ms) {
        if (!ready || !active) return;
        hintIcon = icon;
        hintText = text;
        hintRing = ring;
        hintTimer.interval = ms ?? 1400;
        hintTimer.restart();
    }

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    function hoverIn()  { collapseTimer.stop(); if (!expanded) expandTimer.restart(); }
    function hoverOut() { expandTimer.stop(); if (!pinned) collapseTimer.restart(); }
    function togglePinned() { pinned = !(pinned && expanded); expanded = pinned; }

    Timer { interval: 2000; running: true; onTriggered: root.ready = true }
    Timer { id: hintTimer; interval: 1400; onTriggered: root.hintText = "" }
    Timer { id: notifTimer; interval: 4000; onTriggered: root.notif = null }
    Timer { id: expandTimer; interval: 250; onTriggered: root.expanded = true }
    Timer { id: collapseTimer; interval: 450; onTriggered: { root.expanded = false; root.pinned = false; } }

    // Track position isn't updated automatically by MPRIS
    Timer {
        interval: 1000
        repeat: true
        running: root.playing && root.mode === "expanded"
        onTriggered: root.player.positionChanged()
    }

    // ── Volume (PipeWire, reacts immediately to volume keys) ─────────
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    function volumeHint() {
        if (!Config.islandOsd || !sink?.audio) return;
        const v = Math.min(1, sink.audio.volume);
        hint(sink.audio.muted ? Icons.volumeOff : Icons.volume,
             sink.audio.muted ? "Muted" : Math.round(v * 100) + "%", sink.audio.muted ? 0 : v);
    }

    Connections {
        target: root.sink?.audio ?? null
        ignoreUnknownSignals: true
        function onVolumeChanged() { root.volumeHint(); }
        function onMutedChanged()  { root.volumeHint(); }
    }

    // ── Brightness (periodically read /sys/class/backlight) ──────────
    property string backlight: ""
    property int maxBright: 0

    Process {
        running: true
        command: ["sh", "-c", 'd=$(ls /sys/class/backlight 2>/dev/null | head -n1); [ -n "$d" ] && echo "$d $(cat /sys/class/backlight/$d/max_brightness)"']
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(" ");
                if (p.length === 2 && parseInt(p[1]) > 0) {
                    root.backlight = p[0];
                    root.maxBright = parseInt(p[1]);
                }
            }
        }
    }

    FileView {
        id: brightFile
        property int last: -1
        path: root.backlight !== "" ? "/sys/class/backlight/" + root.backlight + "/brightness" : ""
        printErrors: false
        onLoaded: {
            const v = parseInt(text());
            if (isNaN(v)) return;
            if (last >= 0 && v !== last) {
                const r = v / root.maxBright;
                root.hint(Icons.brightness, Math.round(r * 100) + "%", r);
            }
            last = v;
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.active && Config.islandOsd && root.backlight !== ""
        onTriggered: brightFile.reload()
    }

    // ── Battery: charger plugged / unplugged ─────────────────────────
    Connections {
        target: Battery
        function onChargingChanged() {
            if (!Battery.available) return;
            root.hint(Battery.charging ? Icons.charging : Icons.battery,
                      (Battery.charging ? "Charging " : "On battery ") + Battery.percent + "%",
                      Battery.percent / 100, 2200);
        }
    }

    // ── Workspace switching ──────────────────────────────────────────
    Connections {
        target: Hyprland
        enabled: Config.islandWorkspaceHint
        function onFocusedWorkspaceChanged() {
            const ws = Hyprland.focusedWorkspace;
            if (ws && ws.id > 0) root.hint("", "Workspace " + ws.name, -1, 900);
        }
    }

    // ── Notifications ─────────────────────────────────────────────────
    // While the island is active, regular popups are replaced by it (except critical ones)
    Binding {
        target: Notifications
        property: "islandHandles"
        value: root.active && Config.islandNotifications
    }

    Connections {
        target: Notifications
        function onArrived(n) {
            if (!Notifications.islandHandles) return;
            root.notif = n;
            notifTimer.restart();
            n.closed.connect(() => { if (root.notif === n) root.notif = null; });
        }
    }

    // ── Window, one per monitor ───────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            screen: modelData
            visible: root.active
            anchors.top: true                       // top only = automatically centered
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-island"
            implicitWidth: 560
            implicitHeight: 240
            color: "transparent"

            // Clicks outside the pill pass through to the app below
            mask: Region { item: pill }

            readonly property int compactH: Config.islandHeight
            readonly property int topY: Math.max(2, (root.lay.margin?.top ?? 0) + Math.round((root.lay.height - compactH) / 2))

            // Width follows content (like Tide), capped so it doesn't overflow
            readonly property real targetW: Math.min(520, ({
                idle: idleFace.wantW, media: mediaFace.wantW, hint: hintFace.wantW,
                notif: notifFace.wantW, expanded: root.hasMedia ? 420 : 300
            })[root.mode])
            readonly property real targetH: root.mode === "expanded" ? (root.hasMedia ? 176 : 112) : compactH

            Rectangle {
                id: pill
                x: Math.round((win.width - width) / 2)
                y: win.topY
                width: win.targetW
                height: win.targetH
                radius: root.mode === "expanded" ? 32 : height / 2
                color: IslandStyle.bg
                border.width: Config.islandUseTheme ? 1 : 0
                border.color: Theme.border
                clip: true

                Behavior on width  { SpringAnimation { spring: 3.2; damping: 0.28; epsilon: 0.3 } }
                Behavior on height { SpringAnimation { spring: 3.2; damping: 0.30; epsilon: 0.3 } }
                Behavior on radius { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                HoverHandler {
                    onHoveredChanged: hovered ? root.hoverIn() : root.hoverOut()
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (root.mode === "notif") {
                            if (mouse.button === Qt.RightButton) Notifications.dismiss(root.notif);
                            else Notifications.activate(root.notif);
                            root.notif = null;
                        } else if (mouse.button === Qt.MiddleButton && root.hasMedia) {
                            root.player.togglePlaying();
                        } else if (mouse.button === Qt.LeftButton) {
                            root.togglePinned();
                        }
                    }
                }

                // ── idle: clock ───────────────────────────────────────
                Face {
                    id: idleFace
                    shown: root.mode === "idle"
                    wantW: idleRow.implicitWidth + 44
                    RowLayout {
                        id: idleRow
                        anchors.centerIn: parent
                        spacing: 8
                        IslandText {
                            text: Qt.formatDateTime(BarState.clock.date, Config.islandClockFormat)
                            font.pixelSize: 17
                        }
                        Rectangle {
                            visible: Notifications.count > 0 && !Notifications.dnd
                            implicitWidth: 6; implicitHeight: 6; radius: 3
                            color: IslandStyle.accent
                        }
                    }
                }

                // ── media: title + equalizer ──────────────────────────
                Face {
                    id: mediaFace
                    shown: root.mode === "media"
                    wantW: Math.min(360, mediaTitle.implicitWidth) + 26 + 58
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 18
                        spacing: 10
                        Cover {
                            size: win.compactH - 10
                            radius: (win.compactH - 10) / 2
                            source: root.player?.trackArtUrl ?? ""
                        }
                        IslandText {
                            id: mediaTitle
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: root.player?.trackTitle ?? ""
                            elide: Text.ElideRight
                        }
                        Bars { playing: root.playing; color: IslandStyle.accent }
                    }
                }

                // ── hint: OSD / battery / workspace ───────────────────
                Face {
                    id: hintFace
                    shown: root.mode === "hint"
                    wantW: hintRow.implicitWidth + (root.hintRing >= 0 ? 36 : 56)
                    RowLayout {
                        id: hintRow
                        anchors.left: root.hintRing >= 0 ? parent.left : undefined
                        anchors.leftMargin: 18
                        anchors.horizontalCenter: root.hintRing >= 0 ? undefined : parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        IslandText {
                            visible: root.hintIcon !== ""
                            text: root.hintIcon
                            font.family: Theme.font
                            font.pixelSize: 18
                        }
                        IslandText { text: root.hintText }
                        Item { visible: root.hintRing >= 0; implicitWidth: 34 }
                    }
                    Ring {
                        visible: root.hintRing >= 0
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        size: win.compactH - 12
                        value: root.hintRing
                    }
                }

                // ── notification ──────────────────────────────────────
                Face {
                    id: notifFace
                    shown: root.mode === "notif"
                    wantW: Math.min(440, notifRow.implicitWidth) + 44
                    RowLayout {
                        id: notifRow
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 22
                        spacing: 10
                        IconImage {
                            id: notifIcon
                            implicitSize: 18
                            visible: status === Image.Ready
                            source: {
                                const n = root.notif;
                                if (!n) return "";
                                return Notifications.iconSource(n.image) || Notifications.iconSource(n.appIcon);
                            }
                        }
                        IslandText {
                            visible: !notifIcon.visible
                            text: Icons.bell
                            font.family: Theme.iconFont
                            font.pixelSize: 17
                        }
                        IslandText {
                            Layout.fillWidth: true
                            text: root.notif ? (root.notif.summary || root.notif.appName) : ""
                            elide: Text.ElideRight
                        }
                    }
                }

                // ── expanded: player ─────────────────────────────────
                Face {
                    shown: root.mode === "expanded" && root.hasMedia
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        anchors.topMargin: 16
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            Cover { size: 58; radius: 10; source: root.player?.trackArtUrl ?? "" }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                IslandText {
                                    Layout.fillWidth: true
                                    text: root.player?.trackTitle ?? ""
                                    elide: Text.ElideRight
                                }
                                IslandText {
                                    Layout.fillWidth: true
                                    text: root.player?.trackArtist || root.player?.identity || ""
                                    color: IslandStyle.dim
                                    font.weight: Font.Medium
                                    font.pixelSize: 15
                                    elide: Text.ElideRight
                                }
                            }
                            Bars { playing: root.playing; color: IslandStyle.accent; tall: true }
                        }

                        // Progress + time (click to seek if the player supports it)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            visible: (root.player?.length ?? 0) > 0
                            IslandText { text: root.fmt(root.player?.position); color: IslandStyle.dim; font.pixelSize: 13 }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 5
                                radius: 2.5
                                color: IslandStyle.faint
                                Rectangle {
                                    width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                                    height: parent.height
                                    radius: 2.5
                                    color: IslandStyle.fg
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    enabled: root.player?.canSeek ?? false
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => root.player.position = root.player.length * Math.max(0, Math.min(1, mouse.x / width))
                                }
                            }
                            IslandText { text: root.fmt(root.player?.length); color: IslandStyle.dim; font.pixelSize: 13 }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 44
                            Control { icon: String.fromCodePoint(0xF04AE); enabled: root.player?.canGoPrevious ?? false; onActivated: root.player.previous() }
                            Control {
                                icon: root.playing ? String.fromCodePoint(0xF03E4) : String.fromCodePoint(0xF040A)
                                enabled: root.player?.canTogglePlaying ?? false
                                onActivated: root.player.togglePlaying()
                            }
                            Control { icon: String.fromCodePoint(0xF04AD); enabled: root.player?.canGoNext ?? false; onActivated: root.player.next() }
                        }
                    }
                }

                // ── expanded: no media ────────────────────────────────
                Face {
                    shown: root.mode === "expanded" && !root.hasMedia
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        IslandText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(BarState.clock.date, Config.islandClockFormat)
                            font.pixelSize: 36
                        }
                        IslandText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(BarState.clock.date, "dddd, d MMMM")
                            color: IslandStyle.dim
                            font.weight: Font.Medium
                            font.pixelSize: 15
                        }
                        IslandText {
                            Layout.alignment: Qt.AlignHCenter
                            visible: Weather.available && Config.weatherEnabled
                            text: Weather.icon + "  " + Math.round(Weather.temp) + "°  " + Weather.description
                            color: IslandStyle.dim
                            font.family: Theme.font
                            font.bold: false
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }
    }

    // ── Small components ───────────────────────────────────────────────

    // Island text: white, bold, JetBrainsMono Nerd Font (same as the rest of the UI)
    component IslandText: Text {
        color: IslandStyle.fg
        font.family: IslandStyle.font
        font.pixelSize: 16
        font.weight: Font.DemiBold
    }

    // One island "face"; cross-fades when the mode changes
    component Face: Item {
        property bool shown: false
        property real wantW: 160
        anchors.fill: parent
        opacity: shown ? 1 : 0
        visible: opacity > 0
        scale: shown ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: shown ? 240 : 100 } }
        Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    }

    // Album cover, music icon if there's no image
    component Cover: ClippingRectangle {
        id: cover
        property int size: 24
        property string source: ""
        implicitWidth: size
        implicitHeight: size
        Layout.preferredWidth: size
        Layout.preferredHeight: size
        color: Theme.surface2

        Text {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            text: String.fromCodePoint(0xF075A)
            color: Theme.muted
            font.family: Theme.iconFont
            font.pixelSize: cover.size * 0.5
        }
        Image {
            id: art
            anchors.fill: parent
            source: cover.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 192
            sourceSize.height: 192
        }
    }

    // Fake equalizer that animates while music is playing
    component Bars: Row {
        id: bars
        property bool playing: false
        property bool tall: false
        property color color: "white"
        spacing: 3
        Layout.alignment: Qt.AlignVCenter
        Repeater {
            model: 5
            Rectangle {
                required property int index
                readonly property real peak: (bars.tall ? 20 : 13) - Math.abs(2 - index) * 3
                width: 3
                height: 4
                radius: 1.5
                anchors.verticalCenter: parent.verticalCenter
                color: bars.color
                SequentialAnimation on height {
                    running: bars.playing
                    loops: Animation.Infinite
                    NumberAnimation { to: peak; duration: 240 + index * 55; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 4; duration: 280 + (4 - index) * 50; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // Progress ring (volume / brightness / battery)
    component Ring: Canvas {
        id: ring
        property int size: 22
        property real value: 0
        width: size
        height: size
        onValueChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            const r = size / 2 - 2.5;
            ctx.reset();
            ctx.lineWidth = 3;
            ctx.lineCap = "round";
            ctx.strokeStyle = IslandStyle.faint;
            ctx.beginPath();
            ctx.arc(size / 2, size / 2, r, 0, Math.PI * 2);
            ctx.stroke();
            ctx.strokeStyle = IslandStyle.fg;
            ctx.beginPath();
            ctx.arc(size / 2, size / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0.001, value));
            ctx.stroke();
        }
    }

    // Media buttons
    component Control: Text {
        property string icon: ""
        signal activated()
        text: icon
        color: enabled ? IslandStyle.fg : IslandStyle.faint
        font.family: Theme.iconFont
        font.pixelSize: 28
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activated()
        }
    }
}
