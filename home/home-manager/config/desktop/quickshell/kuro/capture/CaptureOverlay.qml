// GNOME-style screenshot and screen recording controls, opened with Print.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components
import qs.overview

PanelWindow {
    id: root

    property bool open: false
    property string mode: "screenshot"
    property string area: "selection"
    property string audio: "none"
    property bool pendingOpen: false
    property bool awaitingFrame: false
    property string pickMode: ""
    property bool savingScreenshot: false
    property bool draggingSelection: false
    property point selectionStart: Qt.point(0, 0)
    property point selectionEnd: Qt.point(0, 0)
    property string captureError: ""
    property string frozenFrame: ""
    readonly property string freezeDirectory: Config.home + "/.cache/quickshell"
    readonly property string freezePath: freezeDirectory + "/capture-overlay.png"
    readonly property var windowChoices: OverviewState.clients.filter(w =>
        w.monitor === (screen?.name ?? "") && w.ws === (Hyprland.focusedWorkspace?.id ?? -1))

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-capture"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function dismiss() {
        pendingOpen = false;
        pickMode = "";
        draggingSelection = false;
        open = false;
    }

    function toggle() {
        if (open) { dismiss(); return; }
        if (pendingOpen) { pendingOpen = false; return; }
        pendingOpen = true;
        frozenFrame = "";
        const output = screen?.name ?? "";
        freezeProc.command = ["sh", "-c",
            'mkdir -p "$1" && if [ -n "$2" ]; then grim -o "$2" "$3" || grim "$3"; else grim "$3"; fi',
            "sh", freezeDirectory, output, freezePath];
        freezeProc.running = true;
    }

    function activate() {
        if (mode === "record") beginRecording(area, "");
        else chooseArea(area);
    }

    function geometryFor(x, y, w, h) {
        const mon = OverviewState.monitors[screen?.name ?? ""] ?? { x: 0, y: 0 };
        return Math.round(mon.x + x) + "," + Math.round(mon.y + y) + " "
            + Math.round(w) + "x" + Math.round(h);
    }

    function chooseArea(id) {
        area = id;
        captureError = "";
        if (id === "full") {
            if (mode === "screenshot") saveFrozenScreenshot("full", "", freezePath);
            else beginRecording("full", "");
        } else if (id === "window") {
            OverviewState.refresh();
            pickMode = "window";
        } else {
            draggingSelection = false;
            pickMode = "area";
        }
    }

    function saveFrozenScreenshot(kind, geometry, frame) {
        savingScreenshot = true;
        pickMode = "";
        Capture.screenshot(kind, geometry, frame);
    }

    function chooseWindow(windowInfo) {
        const geometry = Math.round(windowInfo.x) + "," + Math.round(windowInfo.y) + " "
            + Math.round(windowInfo.w) + "x" + Math.round(windowInfo.h);
        pickMode = "";
        if (mode === "screenshot") saveFrozenScreenshot("window", geometry, "");
        else beginRecording("window", geometry);
    }

    function beginRecording(kind, geometry) {
        if (Capture.recording) {
            dismiss();
            actionHandoff.stop();
            Qt.callLater(() => Capture.stopRecording());
            return;
        }
        pendingRecordArea = kind;
        pendingRecordGeometry = geometry;
        dismiss();
        actionHandoff.restart();
    }

    property string pendingRecordArea: "full"
    property string pendingRecordGeometry: ""

    onOpenChanged: {
        if (open) {
            mode = Capture.recording ? "record" : "screenshot";
            OverviewState.refresh();
            Qt.callLater(() => overlayFocus.forceActiveFocus());
        }
    }

    Connections {
        target: Capture
        function onScreenshotFinished(success, detail) {
            if (!root.savingScreenshot) return;
            root.savingScreenshot = false;
            if (success) root.dismiss();
            else {
                root.captureError = detail;
                root.open = true;
            }
        }
    }

    Process {
        id: freezeProc
        onExited: (code, status) => {
            if (!root.pendingOpen) return;
            root.pendingOpen = false;
            if (code === 0) {
                root.awaitingFrame = true;
                root.frozenFrame = "file://" + root.freezePath;
            } else {
                root.open = true;
            }
        }
    }

    // Let layer-shell release its input grab before the recorder starts.
    Timer {
        id: actionHandoff
        interval: 120
        onTriggered: {
            Capture.startRecording(root.pendingRecordArea, root.audio, root.pendingRecordGeometry);
        }
    }

    Item {
        id: overlayFocus
        anchors.fill: parent
        focus: root.open

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (root.pickMode !== "") root.pickMode = "";
                else root.dismiss();
                event.accepted = true;
            }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.activate(); event.accepted = true; }
        }

        Rectangle {
            z: 0
            anchors.fill: parent
            color: "transparent"
            Image {
                id: frozenImage
                anchors.fill: parent
                source: root.frozenFrame
                cache: false
                smooth: false
                asynchronous: false
                fillMode: Image.Stretch
                onStatusChanged: {
                    if (!root.awaitingFrame) return;
                    if (status === Image.Ready) {
                        root.awaitingFrame = false;
                        root.open = true;
                    } else if (status === Image.Error) {
                        root.awaitingFrame = false;
                        root.open = true;
                    }
                }
            }
            Rectangle {
                anchors.fill: parent
                color: "#40000000"
                visible: root.pickMode === "" && !root.savingScreenshot
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.pickMode === "" && !root.savingScreenshot
                onClicked: root.dismiss()
            }
        }

        // Region picking happens over the frozen monitor image, not the live desktop.
        MouseArea {
            id: regionPicker
            z: 5
            anchors.fill: parent
            enabled: root.open && root.pickMode === "area"
            cursorShape: Qt.CrossCursor
            onPressed: mouse => {
                root.selectionStart = Qt.point(mouse.x, mouse.y);
                root.selectionEnd = root.selectionStart;
                root.draggingSelection = true;
            }
            onPositionChanged: mouse => {
                if (root.draggingSelection) root.selectionEnd = Qt.point(mouse.x, mouse.y);
            }
            onReleased: mouse => {
                if (!root.draggingSelection) return;
                root.selectionEnd = Qt.point(mouse.x, mouse.y);
                const x = Math.min(root.selectionStart.x, root.selectionEnd.x);
                const y = Math.min(root.selectionStart.y, root.selectionEnd.y);
                const w = Math.abs(root.selectionEnd.x - root.selectionStart.x);
                const h = Math.abs(root.selectionEnd.y - root.selectionStart.y);
                root.draggingSelection = false;
                if (w < 8 || h < 8) return;
                const geometry = root.geometryFor(x, y, w, h);
                if (root.mode === "screenshot") root.saveFrozenScreenshot("selection", geometry, "");
                else root.beginRecording("selection", geometry);
            }
        }

        Rectangle {
            z: 6
            visible: root.open && root.pickMode === "area" && root.draggingSelection
            x: Math.min(root.selectionStart.x, root.selectionEnd.x)
            y: Math.min(root.selectionStart.y, root.selectionEnd.y)
            width: Math.abs(root.selectionEnd.x - root.selectionStart.x)
            height: Math.abs(root.selectionEnd.y - root.selectionStart.y)
            color: "#3360aaff"
            border.color: Theme.accent
            border.width: 2
        }

        Rectangle {
            z: 8
            visible: root.open && root.pickMode === "area"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 28
            width: areaHint.implicitWidth + 28
            height: 38
            color: Theme.bg
            border.color: Theme.border
            radius: 0
            Text {
                id: areaHint
                anchors.centerIn: parent
                text: "Drag to select an area  ·  Esc to cancel"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 12
            }
        }

        Rectangle {
            id: windowPicker
            z: 10
            visible: root.open && root.pickMode === "window"
            width: Math.min(520, parent.width - 32)
            height: Math.min(420, parent.height - 40)
            anchors.centerIn: parent
            color: Theme.bg
            border.color: Theme.border
            radius: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "CHOOSE A WINDOW"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 11
                        font.letterSpacing: 1.2
                    }
                    TextButton { sharp: true; text: "Cancel"; onClicked: root.pickMode = "" }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.windowChoices.length === 0
                    text: "No windows on this screen and workspace."
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: windowList.implicitHeight
                    ColumnLayout {
                        id: windowList
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: root.windowChoices
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 48
                                color: windowMouse.containsMouse ? Theme.surface : "transparent"
                                border.color: Theme.border
                                radius: 0
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 2
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title || modelData.cls || "Window"
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.cls
                                        color: Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    id: windowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.chooseWindow(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: panel
            z: 10
            visible: root.open && root.pickMode === "" && !root.savingScreenshot
            width: Math.min(640, parent.width - 32)
            height: root.mode === "record" ? 260 : 172
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 56
            color: Theme.bg
            border.color: Theme.border
            radius: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "SCREEN CAPTURE"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 11
                        font.letterSpacing: 1.4
                    }
                    TextButton { sharp: true; text: Icons.close; onClicked: root.dismiss() }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [
                            { id: "screenshot", title: "Screenshot", icon: Icons.g(0xF0100) },
                            { id: "record", title: "Record Screen", icon: Icons.g(0xF044A) }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 42
                            color: root.mode === modelData.id ? Theme.surface2 : "transparent"
                            border.color: root.mode === modelData.id ? Theme.accent : Theme.border
                            radius: 0
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: modelData.icon; color: root.mode === modelData.id ? Theme.accent : Theme.subtext; font.family: Theme.iconFont; font.pixelSize: 17 }
                                Text { text: modelData.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 12 }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.mode = modelData.id
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: [
                            { id: "full", title: "Entire screen", icon: Icons.g(0xF0293) },
                            { id: "window", title: "Focused window", icon: Icons.g(0xF05B7) },
                            { id: "selection", title: "Select area", icon: Icons.g(0xF0100) }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 36
                            color: root.area === modelData.id ? Theme.surface : "transparent"
                            border.color: root.area === modelData.id ? Theme.accent : Theme.border
                            radius: 0
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: modelData.icon; color: Theme.subtext; font.family: Theme.iconFont; font.pixelSize: 14 }
                                Text { text: modelData.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 10 }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.chooseArea(modelData.id)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.mode === "record"
                    Text {
                        Layout.fillWidth: true
                        text: "Audio: " + ({ none: "Off", system: "System", external: "Microphone", both: "System + mic" }[root.audio])
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 11
                    }
                    TextButton { sharp: true; text: "Change"; onClicked: root.audio = ({ none: "system", system: "external", external: "both", both: "none" }[root.audio]) }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.mode === "record"
                    Item { Layout.fillWidth: true }
                    TextButton {
                        sharp: true
                        primary: true
                        text: Capture.recording ? "Stop Recording" : "Start Recording"
                        onClicked: root.activate()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.captureError !== ""
                    text: root.captureError
                    color: Theme.danger
                    font.family: Theme.font
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
