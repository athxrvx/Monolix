// OMNI — an Omarchy-style launcher: six sections, one global search.
// Open: SUPER + SPACE, the launcher button in the bar,
// or  qs -c shell ipc call launcher toggle
//
//   1–6 / TAB       jump / cycle section      ↑ ↓ / Ctrl+J K   move
//   Enter           run (twice for danger)    Esc / outside     close
//   = calc   :clip clipboard   :wall wallpapers   :file files   :win windows
//   > command (background)     ? web search
//
// Search logic lives in services/Launcher.qml. Styling comes from Theme.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.services

PanelWindow {
    id: root

    property string query: ""
    property int current: 0
    property int currentAction: 0
    property bool keyboardMode: false
    property var confirmationAction: null

    // Hover flyout state (description moved out of the rows to stay minimal).
    property string tipText: ""
    property real tipY: 0
    property bool pointerPositionKnown: false
    property real lastPointerX: 0
    property real lastPointerY: 0

    readonly property var results: Launcher.open ? Launcher.search(query) : []
    readonly property bool browsing: query.trim() === ""
    readonly property var sections: Launcher.sections
    readonly property int rowH: 50
    readonly property int shownRows: Math.max(1, Math.min(results.length, 9))
    readonly property int shownHeight: {
        let total = 0;
        for (let i = 0; i < shownRows; i++)
            total += results[i]?.kind === "containers"
                ? (results[i]?.rowHeight ?? rowH) : rowH;
        return Math.max(rowH, total);
    }
    readonly property string sectionLabel: Launcher.sections.find(s => s.id === Launcher.section)?.label ?? "Menu"

    // Colors are animated so a palette change fades in.
    property color cBg: Theme.bg
    property color cSurface: Theme.surface
    property color cBorder: Theme.border
    property color cAccent: Theme.accent
    property color cText: Theme.text
    property color cDim: Theme.muted
    Behavior on cBg { ColorAnimation { duration: 300 } }
    Behavior on cAccent { ColorAnimation { duration: 300 } }
    Behavior on cText { ColorAnimation { duration: 300 } }
    Behavior on cDim { ColorAnimation { duration: 300 } }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: Launcher.open

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: Launcher.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None


    function resetSelection() {
        current = 0;
        currentAction = 0;
        confirmationAction = null;
        hideTip();
    }

    function showTip(row) {
        const s = row.result.sub ?? "";
        if (s === "") { tipText = ""; return; }
        const y = panel.y + row.mapToItem(panel, 0, row.height / 2).y;
        if (tipText === s && Math.abs(tipY - y) < 1) return;
        tipY = y;
        tipText = s;
    }
    function hideTip() { tipText = ""; }

    // Delegate-local mouse coordinates can change when the result list is
    // rebuilt even though the physical pointer did not move. Use global
    // coordinates so that layout churn cannot repeatedly steal selection
    // from keyboard navigation or flicker the hover state.
    function pointerMoved(item, x, y) {
        const point = item.mapToGlobal(Qt.point(x, y));
        const moved = !pointerPositionKnown
            || Math.abs(point.x - lastPointerX) + Math.abs(point.y - lastPointerY) > 1;
        pointerPositionKnown = true;
        lastPointerX = point.x;
        lastPointerY = point.y;
        return moved;
    }

    function selectFromPointer(row, index, x, y) {
        if (!pointerMoved(row, x, y)) return;
        keyboardMode = false;
        current = index;
        showTip(row);
    }

    function selectSection(id) {
        field.text = "";
        root.query = "";
        root.resetSelection();
        Launcher.enterSection(id);
        field.forceActiveFocus();
    }

    function move(d) {
        if (results.length === 0) return;
        keyboardMode = true;
        let next = current;
        for (let i = 0; i < results.length; i++) {
            next = (next + d + results.length) % results.length;
            if (!(results[next].kind === "containers" && results[next].containerOptionsLabel)) {
                current = next;
                currentAction = 0;
                break;
            }
        }
        list.positionViewAtIndex(current, ListView.Contain);
    }

    function adjustCurrent(direction) {
        const result = results[current];
        if (!result || typeof result.adjust !== "function") return false;
        result.adjust(direction);
        Launcher.liveTick++;
        return true;
    }

    function requiresPowerConfirmation(result) {
        const command = Array.isArray(result?.run?.cmd) ? result.run.cmd.join(" ") : "";
        return command === "systemctl reboot" || command === "systemctl poweroff";
    }

    function activate(i) {
        const r = results[i];
        if (r.kind === "containers" && r.containerOptionsLabel) return;
        if (r.kind === "containers" && r.containerActionStrip) {
            const action = r.containerActions[currentAction] ?? r.containerActions[0];
            if (action?.enabled !== false) Launcher.run(action);
            return;
        }
        if (requiresPowerConfirmation(r)) {
            confirmationAction = r;
            field.text = "";
            query = "";
            hideTip();
            confirmationField.text = "";
            confirmationField.forceActiveFocus();
            return;
        }
        Launcher.run(r);
    }

    function openConfig(path) {
        Launcher.openConfig(path);
        Launcher.open = false;
    }

    function resolveConfirmation(yes) {
        const action = confirmationAction;
        confirmationAction = null;
        confirmationField.text = "";
        if (yes && action) {
            Launcher.run(action);
        } else {
            field.forceActiveFocus();
        }
    }

    Connections {
        target: Launcher
        function onSectionChanged() { root.resetSelection(); }
        function onDrilledChanged() { root.resetSelection(); }
        function onOpenChanged() {
            if (!Launcher.open) { root.hideTip(); return; }
            root.keyboardMode = false;
            field.text = "";
            root.query = "";
            root.resetSelection();
            field.forceActiveFocus();
        }
    }

    onQueryChanged: {
        if (confirmationAction) return;
        list.smoothScrolling = false;
        wheelSettle.stop();
        resetSelection();
        if (query.startsWith(":clip") && Clipboard.items.length === 0) Clipboard.refresh();
        if (query.startsWith(":file")) Launcher.findFiles(query.slice(5));
    }

    onResultsChanged: if (!confirmationAction && current >= results.length) resetSelection()

    // Click anywhere outside the panel to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: Launcher.open = false
    }

    Rectangle {
        id: panel
        width: Math.min(320, root.width - 80)
        height: Math.min(root.height - 80, 83 + root.shownHeight)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        // Centered using the default menu height, then kept fixed so the
        // panel grows downward instead of jumping when the height changes.
        anchors.topMargin: Math.max(56, Math.round((root.height - (83 + Launcher.rootSections.length * root.rowH)) / 2) + 2)
        color: root.cBg
        border.width: 2
        border.color: root.cAccent

        opacity: Launcher.open ? 1 : 0
        scale: Launcher.open ? 1 : 0.98
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ── Search line ──────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                color: root.cBg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8



                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextInput {
                            id: field
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.cText
                            selectionColor: Theme.selectionBg
                            selectedTextColor: Theme.selectionFg
                            cursorDelegate: Rectangle { width: 2; color: root.cAccent }
                            font.family: Theme.font
                            font.pixelSize: 17
                            clip: true
                            focus: Launcher.open && !root.confirmationAction
                            enabled: !root.confirmationAction
                            onTextChanged: {
                                if (root.confirmationAction) {
                                    const answer = text.toLowerCase();
                                    if (answer.length > 1 || (answer !== "" && answer !== "y" && answer !== "n"))
                                        text = "";
                                    return;
                                }
                                root.query = text;
                            }

                            Keys.onPressed: event => {
                                root.keyboardMode = true;
                                const ctrl = event.modifiers & Qt.ControlModifier;
                                if (event.key === Qt.Key_Escape) {
                                    if (text !== "") text = "";
                                    else if (Launcher.drilled) Launcher.goBack();
                                    else Launcher.open = false;
                                } else if ((event.key === Qt.Key_Left || event.key === Qt.Key_Right)
                                           && text === "" && root.adjustCurrent(event.key === Qt.Key_Right ? 1 : -1)) {
                                    // Live slider rows adjust horizontally while focused.
                                } else if (event.key === Qt.Key_Left && text === "" && Launcher.drilled) {
                                    if (root.results[root.current]?.containerActionStrip) {
                                        const count = root.results[root.current].containerActions.length;
                                        root.currentAction = (root.currentAction + count - 1) % count;
                                    } else Launcher.goBack();
                                } else if (event.key === Qt.Key_Right && root.results[root.current]?.containerActionStrip) {
                                    const count = root.results[root.current].containerActions.length;
                                    root.currentAction = (root.currentAction + 1) % count;
                                } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                                    const sectionIndex = event.key - Qt.Key_1;
                                    if (sectionIndex < Launcher.rootSections.length)
                                        root.selectSection(Launcher.rootSections[sectionIndex].id);
                                } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                    root.selectSection(Launcher.rootSections[
                                        (Launcher.rootSections.findIndex(s => s.id === Launcher.section)
                                         + (event.key === Qt.Key_Tab ? 1 : -1) + Launcher.rootSections.length)
                                        % Launcher.rootSections.length].id);
                                } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) {
                                    root.move(1);
                                } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) {
                                    root.move(-1);
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.activate(root.current);
                                } else {
                                    return;
                                }
                                event.accepted = true;
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: field.text === ""
                            text: Launcher.drilled ? root.sectionLabel + "..." : "Go..."
                            color: root.cDim
                            font.family: Theme.font
                            font.pixelSize: 17
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // ── Results ──────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Keep the pointer shape stable while search results are
                // replaced/reused underneath it. Per-row cursor overrides
                // caused a one-frame fallback between delegate lifetimes.
                HoverHandler {
                    enabled: root.results.length > 0
                    cursorShape: Qt.PointingHandCursor
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.results.length === 0
                    text: root.query.startsWith(":file") && root.query.length < 8 ? "Type at least 4 letters"
                          : "No matches"
                    color: root.cDim
                    font.family: Theme.font
                    font.pixelSize: 13
                }

                ListView {
                    id: list
                    property real wheelTargetY: 0
                    property bool smoothScrolling: false
                    anchors.fill: parent
                    clip: true
                    model: root.results
                    currentIndex: root.current
                    reuseItems: true
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 100
                    highlightResizeDuration: 0
                    Behavior on contentY {
                        enabled: list.smoothScrolling
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }
                    Timer {
                        id: wheelSettle
                        interval: 180
                        onTriggered: {
                            list.wheelTargetY = list.contentY;
                            list.smoothScrolling = false;
                        }
                    }

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool isCurrent: index === root.current
                        readonly property var result: row.modelData

                        width: ListView.view.width
                        height: row.result.kind === "containers"
                                ? (row.result.rowHeight ?? root.rowH) : root.rowH

                        Rectangle {
                            x: 8
                            y: 4
                            width: parent.width - 16
                            height: Math.max(0, row.result.containerCardHeight)
                            visible: row.result.kind === "containers" && row.result.containerHeader
                            color: root.cSurface
                            border.width: 1
                            border.color: root.cBorder
                            radius: 0
                            z: -1
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: row.result.kind === "containers" && row.result.containerCardMember ? 10 : 0
                            visible: !(row.result.kind === "containers"
                                       && (row.result.containerOptionsLabel || row.result.containerActionStrip))
                            color: row.isCurrent
                                   ? Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.26)
                                   : rowMouse.containsMouse
                                     ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.04)
                                     : "transparent"
                            radius: 0
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            visible: !(row.result.kind === "containers"
                                       && (row.result.containerOptionsLabel || row.result.containerActionStrip))
                            anchors.leftMargin: row.result.kind === "containers" && row.result.containerHeader ? 22 : 10
                            anchors.rightMargin: row.result.kind === "containers" && row.result.containerHeader ? 22 : 10
                            spacing: 10

                            // Icon (desktop entry / thumbnail / glyph)
                            Item {
                                implicitWidth: row.result.kind === "menu" ? 30
                                    : row.result.kind === "power" ? 34 : 22
                                implicitHeight: row.result.kind === "power" ? 32 : 24
                                clip: true

                                ClippingRectangle {
                                    anchors.fill: parent
                                    visible: img.status === Image.Ready
                                    color: "transparent"
                                    Image {
                                        id: img
                                        anchors.fill: parent
                                        source: row.result.icon ?? ""
                                        fillMode: row.result.kind === "wall" || row.result.kind === "clip"
                                                  ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                        sourceSize.width: 36
                                        sourceSize.height: 36
                                        asynchronous: true
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: parent.height
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.NoWrap
                                    clip: true
                                    visible: img.status !== Image.Ready
                                    text: row.result.glyph ?? ""
                                    color: row.isCurrent ? root.cAccent : row.result.danger ? Theme.danger : root.cDim
                                    font.family: Theme.iconFont
                                    font.pixelSize: row.result.kind === "power" ? 27
                                        : row.result.kind === "menu" ? 20 : 19
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1
                                Text {
                                    Layout.fillWidth: true
                                    text: row.result.title
                                    color: root.cText
                                    font.family: Theme.font
                                    font.pixelSize: row.result.kind === "containers" && row.result.containerHeader ? 15
                                        : row.result.kind === "calc" ? 17 : 15
                                    font.bold: row.result.kind === "containers" && row.result.containerHeader
                                    elide: Text.ElideRight
                                }
                            }

                            Item {
                                visible: !!row.result.configPath
                                Layout.preferredWidth: visible ? 34 : 0
                                Layout.minimumWidth: visible ? 34 : 0
                                Layout.maximumWidth: visible ? 34 : 0
                                Layout.preferredHeight: 24
                                z: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "Nix ↗"
                                    color: configMouse.containsMouse ? root.cAccent : root.cDim
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: configMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.openConfig(row.result.configPath)
                                }
                            }

                            // Status / category number / search tag
                            Text {
                                Layout.maximumWidth: 96
                                Layout.alignment: Qt.AlignVCenter
                                text: row.result.status === "missing" ? "missing"
                                      : row.result.status === "ok" ? "installed"
                                      : row.result.kind === "control" && row.result.value !== "" ? row.result.value + (row.result.submenu ? "  ›" : "")
                                      : row.result.control !== "" ? row.result.value
                                      : !root.browsing
                                        ? (row.result.section ? row.result.section + "  " : "")
                                          + (row.result.hint ?? "")
                                        : (row.result.kind === "menu" || row.result.submenu)
                                          ? (row.result.hint ?? "") + "  ›"
                                          : row.result.hint ?? ""
                                color: row.result.status === "missing" ? Theme.danger
                                       : row.result.status === "ok" ? Theme.teal
                                       : row.result.kind === "control" && row.result.active ? root.cAccent
                                       : root.cDim
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideLeft
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 18
                            anchors.topMargin: 12
                            anchors.bottomMargin: 12
                            spacing: 10
                            visible: row.result.kind === "containers" && row.result.containerActionStrip

                            Repeater {
                                model: row.result.containerActions

                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: !modelData.enabled
                                           ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.025)
                                           : (actionMouse.containsMouse
                                              || (root.current === row.index && root.currentAction === index))
                                             ? Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.14)
                                             : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.035)
                                    border.width: 1
                                    border.color: !modelData.enabled ? root.cBorder
                                                 : actionMouse.containsMouse
                                                   ? root.cAccent : root.cBorder
                                    radius: 0
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.title
                                        color: modelData.enabled ? root.cText : root.cDim
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        enabled: modelData.enabled
                                        hoverEnabled: true
                                        onEntered: {
                                            if (root.pointerMoved(row, actionMouse.mouseX, actionMouse.mouseY)) {
                                                root.keyboardMode = false;
                                                root.current = row.index;
                                                root.currentAction = index;
                                            }
                                        }
                                        onPositionChanged: mouse => {
                                            if (!root.pointerMoved(row, mouse.x, mouse.y)) return;
                                            root.keyboardMode = false;
                                            root.current = row.index;
                                            root.currentAction = index;
                                        }
                                        onClicked: {
                                            root.current = row.index;
                                            root.currentAction = index;
                                            Launcher.run(modelData);
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.result.kind === "containers" && row.result.containerOptionsLabel
                            text: row.result.title.toUpperCase()
                            color: root.cDim
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.letterSpacing: 1.1
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: row.result.containerHeader ? 18 : 38
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.bottom: parent.bottom
                            height: 1
                            visible: row.result.kind === "containers" && row.result.containerHeader
                            color: root.cBorder
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            z: -1
                            enabled: !(row.result.kind === "containers"
                                          && (row.result.containerOptionsLabel || row.result.containerActionStrip))
                            hoverEnabled: true
                            onEntered: root.selectFromPointer(row, row.index, rowMouse.mouseX, rowMouse.mouseY)
                            onPositionChanged: mouse => root.selectFromPointer(row, row.index, mouse.x, mouse.y)
                            onExited: root.hideTip()
                            onClicked: root.activate(row.index)
                            onWheel: wheel => {
                                const usesPixels = wheel.pixelDelta.y !== 0;
                                const delta = usesPixels
                                    ? wheel.pixelDelta.y * 0.65
                                    : wheel.angleDelta.y / 120 * root.rowH * 0.72;
                                if (delta === 0) return;
                                if (row.result.adjust) {
                                    root.current = row.index;
                                    root.adjustCurrent(delta > 0 ? 1 : -1);
                                } else {
                                    if (!wheelSettle.running)
                                        list.wheelTargetY = list.contentY;
                                    list.smoothScrolling = true;
                                    list.wheelTargetY = Math.max(0, Math.min(
                                        list.contentHeight - list.height,
                                        list.wheelTargetY - delta));
                                    list.contentY = list.wheelTargetY;
                                    wheelSettle.restart();
                                }
                                wheel.accepted = true;
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: 3
                    radius: 1.5
                    color: root.cSurface
                    visible: list.contentHeight > list.height

                    Rectangle {
                        width: parent.width
                        height: Math.min(parent.height, Math.max(24,
                            parent.height * list.height / Math.max(1, list.contentHeight)))
                        radius: parent.radius
                        color: root.cAccent
                        y: list.contentHeight <= list.height ? 0
                            : list.contentY / (list.contentHeight - list.height)
                                * (parent.height - height)
                    }
                }

            }
        }
    }

    // Small centered modal for session actions that need typed confirmation.
    Rectangle {
        anchors.fill: parent
        visible: root.confirmationAction !== null
        color: Qt.rgba(0, 0, 0, 0.56)
        z: 20

        MouseArea { anchors.fill: parent }
    }

    Rectangle {
        id: confirmationWindow
        width: Math.min(360, root.width - 32)
        height: 124
        anchors.centerIn: parent
        visible: root.confirmationAction !== null
        color: root.cBg
        border.width: 1
        border.color: root.cBorder
        z: 21

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                color: root.cSurface

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    Text {
                        text: "You sure? / "
                        color: root.cAccent
                        font.family: Theme.font
                        font.pixelSize: 14
                    }

                    TextInput {
                        id: confirmationField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.cText
                        selectionColor: Theme.selectionBg
                        selectedTextColor: Theme.selectionFg
                        cursorDelegate: Rectangle { width: 2; color: root.cAccent }
                        font.family: Theme.font
                        font.pixelSize: 14
                        maximumLength: 1
                        focus: root.confirmationAction !== null
                        onTextChanged: {
                            const answer = text.toLowerCase();
                            if (answer !== "" && answer !== "y" && answer !== "n") text = "";
                        }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.resolveConfirmation(false);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                const answer = text.trim().toLowerCase();
                                if (answer === "y") root.resolveConfirmation(true);
                                else if (answer === "n") root.resolveConfirmation(false);
                                event.accepted = true;
                            } else if (event.key !== Qt.Key_Backspace
                                       && event.text.toLowerCase() !== "y"
                                       && event.text.toLowerCase() !== "n") {
                                event.accepted = true;
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Type y or n, then press Enter · Esc cancels"
                color: root.cDim
                font.family: Theme.font
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }

    // ── Hover flyout: the description that used to sit under each row ──
    Rectangle {
        id: tooltip
        visible: root.tipText !== "" && Launcher.open
        x: Math.min(root.width - width - 8, panel.x + panel.width + 8)
        y: root.tipY - height / 2
        width: Math.min(280, Math.max(70, tipLabel.implicitWidth + 18))
        height: 26
        color: root.cSurface
        border.width: 1
        border.color: root.cBorder

        Text {
            id: tipLabel
            anchors.centerIn: parent
            width: parent.width - 16
            text: root.tipText
            color: root.cText
            font.family: Theme.font
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }
}
