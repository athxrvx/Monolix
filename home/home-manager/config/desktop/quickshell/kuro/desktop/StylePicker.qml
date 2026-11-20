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
        if (which === "wallpaper") Wallpaper.refresh();
        selected = which === "wallpaper"
            ? Math.max(0, Wallpaper.images.indexOf(Wallpaper.current))
            : Math.max(0, Config.kuroSchemes.findIndex(s => s.id === Config.kuroScheme));
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

    onEntriesChanged: if (open && mode === "wallpaper") {
        selected = Math.max(0, Wallpaper.images.indexOf(Wallpaper.current));
        Qt.callLater(() => cards.currentIndex = selected);
    }

    Rectangle {
        anchors.fill: parent
        color: "#99000000"
        MouseArea { anchors.fill: parent; onClicked: root.open = false }
    }

    Rectangle {
        id: panel
        width: Math.min(1060, root.width - 48)
        height: 390
        anchors.centerIn: parent
        color: Theme.bg
        border.width: 1
        border.color: Theme.border

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

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
                    text: root.entries.length + " choices  ·  ← → browse  ·  Enter apply  ·  Esc close"
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
                    text: root.mode === "wallpaper" ? "No wallpapers found" : "No themes found"
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
                    currentIndex: root.selected
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 160
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: width / 2 - 150
                    preferredHighlightEnd: width / 2 + 150
                    snapMode: ListView.SnapToItem
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
                        width: 286
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

                                Image {
                                    anchors.fill: parent
                                    visible: root.mode === "wallpaper"
                                    source: root.mode === "wallpaper" ? "file://" + card.modelData : ""
                                    sourceSize.width: 600
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
                                        Rectangle { required property string modelData; width: parent.width / 4; height: parent.height / 4; color: modelData }
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
