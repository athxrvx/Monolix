// Horizontal wallpaper and colorscheme picker, opened from desktop gestures.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: root

    property bool open: false
    property string mode: "wallpaper"
    property int selected: 0
    property string selectedWallpaperPath: ""
    property real wheelRemainder: 0

    readonly property var entries: mode === "wallpaper" ? Wallpaper.images : (Config.kuroSchemes ?? [])
    readonly property string heading: mode === "wallpaper" ? "Choose wallpaper" : "Choose theme"

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-style-picker"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None


    function show(which) {
        mode = which;
        wheelRemainder = 0;
        if (which === "wallpaper") Wallpaper.refresh(true);
        selected = which === "wallpaper"
            ? Math.max(0, Wallpaper.images.indexOf(Wallpaper.current))
            : Math.max(0, Config.kuroSchemes.findIndex(s => s.id === Config.kuroScheme));
        selectedWallpaperPath = which === "wallpaper" ? (Wallpaper.images[selected] ?? "") : "";
        open = true;
        Qt.callLater(() => { cards.currentIndex = selected; cards.forceActiveFocus(); });
    }

    function apply(index) {
        const entry = entries[index];
        if (entry === undefined) return;
        if (mode === "wallpaper") Wallpaper.set(entry);
        else Kuro.setScheme(entry.id);
        open = false;
    }

    function localFileUrl(path) {
        if (!path) return "";
        return "file://" + path.split("/").map(part => encodeURIComponent(part)).join("/");
    }

    onEntriesChanged: if (open && mode === "wallpaper") {
        const previousIndex = Wallpaper.images.indexOf(selectedWallpaperPath);
        selected = previousIndex >= 0 ? previousIndex
            : Math.max(0, Wallpaper.images.indexOf(Wallpaper.current));
        Qt.callLater(() => cards.currentIndex = selected);
    }
    onSelectedChanged: if (mode === "wallpaper" && selected >= 0 && selected < Wallpaper.images.length)
        selectedWallpaperPath = Wallpaper.images[selected]

    Timer {
        interval: 5000
        repeat: true
        running: root.open && root.mode === "wallpaper"
        onTriggered: Wallpaper.refresh(true)
    }

    Rectangle {
        anchors.fill: parent
        color: "#99000000"
        MouseArea { anchors.fill: parent; onClicked: root.open = false }
    }

    Rectangle {
        id: panel
        width: Math.max(1, Math.min(1060, root.width - 32))
        height: Math.max(1, Math.min(440, root.height - 32))
        anchors.centerIn: parent
        color: Theme.bg
        border.width: 1
        border.color: Theme.border

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.min(22, Math.max(12, panel.width * 0.022))
            spacing: Math.min(14, Math.max(8, panel.height * 0.035))

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.heading
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 20
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.entries.length + " choices  ·  wheel / ← → browse  ·  Enter apply  ·  Esc close"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    visible: root.entries.length === 0
                    text: root.mode === "wallpaper"
                        ? (Wallpaper.loading ? "Loading wallpapers…"
                            : Wallpaper.error !== "" ? Wallpaper.error : "No wallpapers found")
                        : "No themes found"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }

                ListView {
                    id: cards
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    spacing: 14
                    clip: true
                    model: root.entries
                    reuseItems: true
                    cacheBuffer: Math.min(width, 572)
                    currentIndex: root.selected
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 220
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: width / 2 - Math.min(143, width * 0.36)
                    preferredHighlightEnd: width / 2 + Math.min(143, width * 0.36)
                    snapMode: ListView.SnapToItem
                    Behavior on contentX {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    focus: root.open
                    onCurrentIndexChanged: root.selected = currentIndex
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) { root.open = false; event.accepted = true; }
                        else if (event.key === Qt.Key_Left) { decrementCurrentIndex(); event.accepted = true; }
                        else if (event.key === Qt.Key_Right) { incrementCurrentIndex(); event.accepted = true; }
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.apply(currentIndex); event.accepted = true; }
                    }

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        required property int index
                        width: Math.min(286, Math.max(180, (cards.width - cards.spacing * 2) * 0.76))
                        height: cards.height - 8
                        y: 4
                        color: cards.currentIndex === index ? Theme.surface2 : Theme.surface
                        border.width: cards.currentIndex === index ? 2 : 1
                        border.color: cards.currentIndex === index ? Theme.accent : Theme.border

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                Rectangle {
                                    anchors.fill: parent
                                    visible: root.mode === "wallpaper"
                                        && wallpaperPreview.status !== Image.Ready
                                    color: Theme.surface
                                    Text {
                                        anchors.centerIn: parent
                                        text: wallpaperPreview.status === Image.Error
                                            ? "Preview unavailable" : "Loading preview…"
                                        color: Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 2
                                    }
                                }

                                Image {
                                    id: wallpaperPreview
                                    anchors.fill: parent
                                    visible: root.mode === "wallpaper"
                                    source: root.mode === "wallpaper"
                                        ? root.localFileUrl(Wallpaper.thumbnail(card.modelData)) : ""
                                    sourceSize: Qt.size(Math.min(480, card.width * 1.5), Math.min(320, card.width))
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }

                                Grid {
                                    anchors.fill: parent
                                    visible: root.mode === "theme"
                                    columns: 4
                                    Repeater {
                                        model: (card.modelData.palette ?? Theme.palette).slice(0, 16)
                                        Rectangle {
                                            required property string modelData
                                            width: parent.width / 4
                                            height: parent.height / 4
                                            color: modelData
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Theme.border
                                }

                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.mode === "wallpaper"
                                    ? Wallpaper.fileName(card.modelData)
                                    : (card.modelData.name ?? card.modelData.id)
                                color: cards.currentIndex === card.index ? Theme.accent : Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        TapHandler {
                            onTapped: cards.currentIndex = card.index
                            onDoubleTapped: root.apply(card.index)
                        }
                    }
                }

                MouseArea {
                    anchors.fill: cards
                    acceptedButtons: Qt.NoButton
                    z: 2
                    onWheel: event => {
                        const angle = event.angleDelta.x !== 0 ? event.angleDelta.x
                            : event.angleDelta.y;
                        const pixels = event.pixelDelta.x !== 0 ? event.pixelDelta.x
                            : event.pixelDelta.y;
                        const delta = angle !== 0 ? angle / 120 * 50 : pixels;
                        if (delta === 0) return;
                        root.wheelRemainder += delta;
                        const steps = Math.trunc(root.wheelRemainder / 50);
                        if (steps === 0) {
                            event.accepted = true;
                            return;
                        }
                        root.wheelRemainder -= steps * 50;
                        root.selected = Math.max(0, Math.min(root.entries.length - 1,
                            root.selected - steps));
                        cards.positionViewAtIndex(root.selected, ListView.Contain);
                        event.accepted = true;
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 3
                    radius: 1.5
                    color: Theme.surface2
                    visible: cards.contentWidth > cards.width

                    Rectangle {
                        width: Math.min(parent.width, Math.max(24,
                            parent.width * cards.width / Math.max(cards.width, cards.contentWidth)))
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                        x: (cards.contentWidth <= cards.width ? 0
                            : cards.contentX / (cards.contentWidth - cards.width)
                                * (parent.width - width))
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                TextButton { text: "‹"; enabled: cards.currentIndex > 0; onClicked: cards.decrementCurrentIndex() }
                Item { Layout.fillWidth: true }
                TextButton { text: "Cancel"; onClicked: root.open = false }
                TextButton { primary: true; text: "Apply"; enabled: root.entries.length > 0; onClicked: root.apply(cards.currentIndex) }
                TextButton { text: "›"; enabled: cards.currentIndex < root.entries.length - 1; onClicked: cards.incrementCurrentIndex() }
            }
        }
    }
}
