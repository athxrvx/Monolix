// Persistent two-tab Kuro sidebar: local Ollama chat and ani-cli anime search.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.bar
import qs.config
import qs.components

PanelWindow {
    id: root

    property bool opened: false
    property int activeTab: 0
    property string modelName: ""
    property var models: []
    property bool modelPickerOpen: false
    property string modelStatus: "Checking Ollama…"
    property var messages: []
    property bool chatBusy: false
    property string chatError: ""
    property var pendingAction: null
    property string animeStatus: "Search with ani-cli, choose a series and episode, then mpv plays it."
    property var pendingAniArgs: []
    property bool animeMenuMode: false
    property string animeMenuPrompt: ""
    property string animeMenuInputPath: ""
    property string animeMenuOutputPath: ""
    property var animeChoices: []
    property string animeFilter: ""
    readonly property var visibleAnimeChoices: animeChoices.filter(item =>
        animeFilter.trim() === "" || String(item).toLowerCase().includes(animeFilter.trim().toLowerCase()))

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: opened || closeTimer.running
    anchors { top: true; bottom: true; left: true }
    margins {
        top: BarState.layout.height + (BarState.layout.margin.top ?? 0) + Theme.popupGap
        bottom: 12
        left: 12
    }
    implicitWidth: 460
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-sidebar"
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function toggle() { opened ? close() : open() }
    function open() {
        opened = true;
        if (activeTab === 0 && models.length === 0) refreshModels();
        Qt.callLater(() => body.forceActiveFocus());
    }
    function close() {
        if (animeMenuMode) finishAnimeMenu("");
        opened = false;
        closeTimer.restart();
    }
    function selectTab(index) {
        activeTab = index;
        modelPickerOpen = false;
        if (index === 0 && models.length === 0) refreshModels();
    }
    function refreshModels() {
        modelStatus = "Loading installed models…";
        modelsProc.command = ["curl", "-fsS", "http://127.0.0.1:11434/api/tags"];
        modelsProc.running = true;
    }
    function sendChat() {
        const prompt = composer.text.trim();
        const model = modelName.trim();
        if (prompt === "" || model === "" || chatBusy || pendingAction !== null) return;
        messages = messages.concat([{ role: "user", content: prompt }]);
        composer.text = "";
        requestChat();
    }
    function requestChat() {
        const model = modelName.trim();
        if (model === "" || chatBusy) return;
        chatBusy = true;
        chatError = "";
        const payload = JSON.stringify({
            model: model,
            messages: [{ role: "system", content: "You are the Kuro desktop shell assistant. You may request only the provided theme, font, or system-update actions. Never request or suggest arbitrary commands or scripts. Action requests are proposals: wait for the user's approval before saying they ran." }].concat(messages),
            stream: false,
            tools: [
                { type: "function", function: { name: "kuro_set_theme", description: "Request a Kuro colorscheme change. Ask for approval before using.", parameters: { type: "object", properties: { theme: { type: "string", enum: Config.kuroSchemes.map(item => item.id) } }, required: ["theme"] } } },
                { type: "function", function: { name: "kuro_set_font", description: "Request an approved terminal, shell, and bar font change. Ask for approval before using.", parameters: { type: "object", properties: { family: { type: "string", enum: ["JetBrainsMono Nerd Font", "CaskaydiaCove Nerd Font", "FiraCode Nerd Font", "Iosevka Nerd Font"] } }, required: ["family"] } } },
                { type: "function", function: { name: "kuro_update_system", description: "Request a full Arch Linux system update. This is a privileged action and always requires explicit user approval.", parameters: { type: "object", properties: {}, additionalProperties: false } } }
            ]
        });
        chatProc.command = [
            "curl", "-fsS", "http://127.0.0.1:11434/api/chat",
            "-H", "Content-Type: application/json",
            "-d", payload
        ];
        chatProc.running = true;
    }
    function receiveChatResponse(result) {
        chatBusy = false;
        const calls = result.message?.tool_calls ?? [];
        if (calls.length > 0) {
            const call = calls[0].function ?? {};
            let args = call.arguments ?? {};
            if (typeof args === "string") {
                try { args = JSON.parse(args); } catch (e) { args = {}; }
            }
            const name = String(call.name ?? "");
            let action = null;
            if (name === "kuro_set_theme") {
                const theme = Config.kuroSchemes.find(item => item.id === String(args.theme ?? ""));
                if (theme) action = { name: name, title: "Change theme to " + theme.name, script: "ai-theme", args: [theme.id] };
            } else if (name === "kuro_set_font") {
                const family = String(args.family ?? "");
                if (["JetBrainsMono Nerd Font", "CaskaydiaCove Nerd Font", "FiraCode Nerd Font", "Iosevka Nerd Font"].includes(family))
                    action = { name: name, title: "Change shell, bar, and terminal font", detail: family, script: "ai-font", args: [family] };
            } else if (name === "kuro_update_system") {
                action = { name: name, title: "Update the Arch Linux system", script: "ai-update", args: [] };
            }
            if (!action) {
                chatError = "That requested action is unavailable or has invalid arguments.";
                if (result.message?.content) messages = messages.concat([{ role: "assistant", content: result.message.content }]);
                return;
            }
            pendingAction = action;
            messages = messages.concat([{ role: "assistant", content: result.message?.content || ("I can " + action.title + (action.detail ? " · " + action.detail : "") + ". Choose whether to run it below.") }]);
            return;
        }
        messages = messages.concat([
            { role: "assistant", content: result.message?.content ?? "Ollama returned an empty response." }
        ]);
    }
    function approveAction() {
        if (!pendingAction) return;
        const action = pendingAction;
        pendingAction = null;
        const script = Config.home + "/.config/quickshell/shell/bin/" + action.script;
        if (action.script === "ai-update") {
            Quickshell.execDetached(Config.popupTerminal.concat([script]));
            messages = messages.concat([{ role: "assistant", content: "Opened the approved system update in a floating terminal." }]);
            return;
        }
        aiActionProc.command = [script].concat(action.args ?? []);
        aiActionProc.running = true;
    }
    function rejectAction() {
        if (!pendingAction) return;
        pendingAction = null;
        messages = messages.concat([{ role: "assistant", content: "Action cancelled." }]);
    }
    function startAnimeSearch() {
        const query = animeQuery.text.trim();
        if (query === "") {
            animeStatus = "Enter an anime title to search.";
            return;
        }
        pendingAniArgs = [query];
        animeStatus = "Searching anime…";
        aniCheck.command = ["sh", "-c", "test -x \"$HOME/.config/quickshell/shell/bin/ani-cli\" && command -v mpv >/dev/null 2>&1 && command -v script >/dev/null 2>&1"];
        aniCheck.running = true;
    }
    function continueAnime() {
        pendingAniArgs = ["--continue"];
        animeStatus = "Opening ani-cli history…";
        aniCheck.command = ["sh", "-c", "test -x \"$HOME/.config/quickshell/shell/bin/ani-cli\" && command -v mpv >/dev/null 2>&1 && command -v script >/dev/null 2>&1"];
        aniCheck.running = true;
    }
    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }
    function runAniCli() {
        const script = Config.home + "/.config/quickshell/shell/bin/ani-cli";
        const menu = Config.home + "/.config/quickshell/shell/bin/ani-menu";
        const command = ["env", "ANI_CLI_MENU=" + shellQuote(menu), "ANI_CLI_PLAYER=mpv",
            shellQuote(script)].concat(pendingAniArgs.map(shellQuote)).join(" ");
        Quickshell.execDetached(["script", "-q", "-e", "-c", command, "/dev/null"]);
    }
    function requestAnimeMenu(prompt, inputPath, outputPath) {
        opened = true;
        activeTab = 1;
        animeMenuMode = true;
        animeMenuPrompt = prompt;
        animeMenuInputPath = inputPath;
        animeMenuOutputPath = outputPath;
        animeFilter = "";
        animeChoices = [];
        animeOptionsProc.command = ["cat", inputPath];
        animeOptionsProc.running = true;
        Qt.callLater(() => animeFilterField.forceFocus());
        return "ok";
    }
    function acceptAnimeChoice() {
        const choices = visibleAnimeChoices;
        if (choices.length > 0) finishAnimeMenu(choices[0]);
    }
    function finishAnimeMenu(choice) {
        const outputPath = animeMenuOutputPath;
        if (!animeMenuMode || outputPath === "") return;
        animeMenuMode = false;
        animeMenuOutputPath = "";
        animeStatus = choice === "" ? "Selection cancelled." : "Selected " + String(choice).replace(/^\s*\d+\s+/, "");
        animeResponseProc.command = [
            "sh", "-c", "printf '%s\\n' \"$1\" > \"$2\"", "sh", String(choice), outputPath
        ];
        animeResponseProc.running = true;
    }

    Timer {
        id: closeTimer
        interval: 190
        onTriggered: {}
    }

    Process {
        id: modelsProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    root.models = (result.models ?? []).map(item => item.name).filter(Boolean);
                    if (root.modelName === "" && root.models.length > 0)
                        root.modelName = root.models[0];
                    root.modelStatus = root.models.length > 0
                        ? root.models.length + " local model" + (root.models.length === 1 ? "" : "s")
                        : "No local models. Run ollama pull <model>.";
                } catch (e) {
                    root.modelStatus = "Ollama did not return a model list.";
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "" && root.models.length === 0)
                    root.modelStatus = "Ollama is unavailable at 127.0.0.1:11434.";
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0 && root.models.length === 0)
                root.modelStatus = "Ollama is unavailable at 127.0.0.1:11434.";
        }
    }

    Process {
        id: chatProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    if (result.error) {
                        root.chatBusy = false;
                        root.chatError = result.error;
                    } else {
                        root.receiveChatResponse(result);
                    }
                } catch (e) {
                    root.chatBusy = false;
                    root.chatError = "Could not read Ollama's response.";
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.chatError = text.trim()
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.chatBusy = false;
                if (root.chatError === "") root.chatError = "Could not reach Ollama at 127.0.0.1:11434.";
            }
        }
    }

    Process {
        id: aiActionProc
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.chatError = text.trim()
        }
        onExited: exitCode => {
            if (exitCode === 0)
                root.messages = root.messages.concat([{ role: "assistant", content: "Approved action completed." }]);
            else
                root.chatError = "The approved action failed (exit " + exitCode + ").";
        }
    }

    Process {
        id: aniCheck
        onExited: exitCode => {
            if (exitCode === 0) {
                root.runAniCli();
                root.animeStatus = "Ani-cli is searching. Anime and episode choices appear here; playback uses MPV.";
            } else {
                root.animeStatus = "Ani-cli, mpv, or the util-linux script tool is missing.";
            }
        }
    }

    Process {
        id: animeOptionsProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.animeMenuMode) return;
                root.animeChoices = text.split("\n").filter(line => line.trim() !== "");
                root.animeFilter = "";
                Qt.callLater(() => animeFilterField.forceFocus());
            }
        }
    }

    Process { id: animeResponseProc }

    Rectangle {
        id: surface
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width
        x: root.opened ? 0 : -width
        color: Theme.bg
        border.width: 1
        border.color: Theme.accent
        clip: true
        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Item {
            id: body
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close();
                    event.accepted = true;
                } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_1) {
                    root.selectTab(0);
                    event.accepted = true;
                } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_2) {
                    root.selectTab(1);
                    event.accepted = true;
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "KURO  /  SIDEBAR"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 15
                        font.letterSpacing: 1
                    }
                    TextButton { text: Icons.close; onClicked: root.close() }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    TextButton {
                        Layout.fillWidth: true
                        text: "Ollama chat"
                        primary: root.activeTab === 0
                        sharp: true
                        onClicked: root.selectTab(0)
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: "Anime"
                        primary: root.activeTab === 1
                        sharp: true
                        onClicked: root.selectTab(1)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.activeTab === 1 && root.animeMenuMode ? 2 : root.activeTab

                    ColumnLayout {
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            InputField {
                                id: modelField
                                text: root.modelName
                                placeholder: "Ollama model name"
                                onTextChanged: root.modelName = text
                            }
                            TextButton {
                                text: "Models"
                                onClicked: {
                                    root.modelPickerOpen = !root.modelPickerOpen;
                                    if (root.models.length === 0) root.refreshModels();
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.modelStatus
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: root.modelPickerOpen
                            spacing: 3
                            Repeater {
                                model: root.models
                                delegate: TextButton {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    text: modelData
                                    sharp: true
                                    onClicked: {
                                        root.modelName = modelData;
                                        modelField.text = modelData;
                                        root.modelPickerOpen = false;
                                    }
                                }
                            }
                        }

                        Flickable {
                            id: chatScroll
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            contentWidth: width
                            contentHeight: messageColumn.implicitHeight
                            onContentHeightChanged: Qt.callLater(() => chatScroll.contentY = Math.max(0, chatScroll.contentHeight - chatScroll.height))

                            ColumnLayout {
                                id: messageColumn
                                width: chatScroll.width
                                spacing: 8

                                Text {
                                    Layout.fillWidth: true
                                    visible: root.messages.length === 0
                                    text: "Local chat via Ollama. Choose a model, then send a message."
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                }

                                Repeater {
                                    model: root.messages
                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        implicitHeight: messageLayout.implicitHeight + 18
                                        color: modelData.role === "user" ? Theme.surface : Theme.bgAlt
                                        border.color: Theme.border
                                        radius: 0

                                        ColumnLayout {
                                            id: messageLayout
                                            anchors.fill: parent
                                            anchors.margins: 9
                                            spacing: 4
                                            Text {
                                                text: modelData.role === "user" ? "YOU" : "OLLAMA"
                                                color: modelData.role === "user" ? Theme.accent : Theme.muted
                                                font.family: Theme.font
                                                font.pixelSize: 10
                                                font.letterSpacing: 1
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.content
                                                color: Theme.text
                                                font.family: Theme.font
                                                font.pixelSize: Theme.fontSize - 2
                                                wrapMode: Text.Wrap
                                                textFormat: Text.PlainText
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    visible: root.pendingAction !== null
                                    implicitHeight: pendingActionLayout.implicitHeight + 18
                                    color: Theme.surface
                                    border.color: Theme.accent
                                    ColumnLayout {
                                        id: pendingActionLayout
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 8
                                        Text {
                                            Layout.fillWidth: true
                                            text: root.pendingAction ? root.pendingAction.title + (root.pendingAction.detail ? " · " + root.pendingAction.detail : "") : ""
                                            color: Theme.text
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 2
                                            wrapMode: Text.Wrap
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: "Only the selected allowlisted script will run."
                                            color: Theme.muted
                                            font.family: Theme.font
                                            font.pixelSize: 10
                                            wrapMode: Text.Wrap
                                        }
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Item { Layout.fillWidth: true }
                                            TextButton { text: "Cancel"; onClicked: root.rejectAction() }
                                            TextButton { text: "Run script"; primary: true; onClicked: root.approveAction() }
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.chatBusy || root.chatError !== ""
                            text: root.chatBusy ? "Thinking…" : root.chatError
                            color: root.chatBusy ? Theme.muted : Theme.danger
                            font.family: Theme.font
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 86
                            color: Theme.surface
                            border.color: composer.activeFocus ? Theme.accent : Theme.border
                            clip: true

                            TextEdit {
                                id: composer
                                anchors.fill: parent
                                anchors.margins: 10
                                color: Theme.text
                                selectionColor: Theme.selectionBg
                                selectedTextColor: Theme.selectionFg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                wrapMode: TextEdit.Wrap
                                selectByMouse: true
                                clip: true
                                Keys.onPressed: event => {
                                    if ((event.modifiers & Qt.ControlModifier)
                                        && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                        root.sendChat();
                                        event.accepted = true;
                                    }
                                }
                            }
                            Text {
                                anchors.fill: composer
                                anchors.margins: 10
                                enabled: false
                                visible: composer.text === ""
                                text: "Message Ollama…  Ctrl+Enter to send"
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                wrapMode: Text.Wrap
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            TextButton {
                                text: "Clear chat"
                                onClicked: { root.messages = []; root.chatError = ""; root.pendingAction = null; }
                            }
                            Item { Layout.fillWidth: true }
                            TextButton {
                                text: root.chatBusy ? "Thinking…" : "Send"
                                primary: true
                                enabled: !root.chatBusy && root.pendingAction === null && root.modelName.trim() !== "" && composer.text.trim() !== ""
                                onClicked: root.sendChat()
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: "ANIME"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                            font.letterSpacing: 1.4
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Search with ani-cli. Choose a title and episode in this sidebar; MPV handles playback."
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                            wrapMode: Text.Wrap
                        }

                        InputField {
                            id: animeQuery
                            placeholder: "Anime title"
                            onAccepted: root.startAnimeSearch()
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            TextButton {
                                Layout.fillWidth: true
                                text: "Search anime"
                                primary: true
                                onClicked: root.startAnimeSearch()
                            }
                            TextButton {
                                Layout.fillWidth: true
                                text: "Continue"
                                onClicked: root.continueAnime()
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: statusText.implicitHeight + 20
                            color: Theme.surface
                            border.color: Theme.border
                            Text {
                                id: statusText
                                anchors.fill: parent
                                anchors.margins: 10
                                text: root.animeStatus
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            Layout.fillWidth: true
                            text: "Search results and episode selection stay in this shell panel. MPV opens for playback."
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 10
                            wrapMode: Text.Wrap
                        }
                    }

                    ColumnLayout {
                        spacing: 10

                        Text {
                            Layout.fillWidth: true
                            text: root.animeMenuPrompt.toUpperCase()
                            color: Theme.accent
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.letterSpacing: 1
                            elide: Text.ElideRight
                        }

                        InputField {
                            id: animeFilterField
                            text: root.animeFilter
                            placeholder: "Filter choices…"
                            onTextChanged: root.animeFilter = text
                            onAccepted: root.acceptAnimeChoice()
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.visibleAnimeChoices.length === 0
                            text: root.animeChoices.length === 0 ? "Loading choices…" : "No matching choices."
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                        }

                        ListView {
                            id: animeList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: root.visibleAnimeChoices
                            currentIndex: 0
                            boundsBehavior: Flickable.StopAtBounds
                            delegate: Rectangle {
                                required property string modelData
                                required property int index
                                width: ListView.view.width
                                height: 40
                                color: animeRowMouse.containsMouse || animeList.currentIndex === index
                                       ? Theme.surface : "transparent"
                                border.color: animeRowMouse.containsMouse ? Theme.border : "transparent"
                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: Text.AlignVCenter
                                    text: modelData.replace(/^\s*\d+\s+/, "")
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 2
                                    elide: Text.ElideRight
                                }
                                MouseArea {
                                    id: animeRowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: animeList.currentIndex = index
                                    onClicked: root.finishAnimeMenu(modelData)
                                }
                            }
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down) {
                                    animeList.currentIndex = Math.min(animeList.count - 1, animeList.currentIndex + 1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    animeList.currentIndex = Math.max(0, animeList.currentIndex - 1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.acceptAnimeChoice();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) {
                                    root.finishAnimeMenu("");
                                    event.accepted = true;
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: root.visibleAnimeChoices.length + " choices"
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 10
                            }
                            TextButton { text: "Cancel"; onClicked: root.finishAnimeMenu("") }
                            TextButton {
                                text: "Select"
                                primary: true
                                enabled: root.visibleAnimeChoices.length > 0
                                onClicked: root.acceptAnimeChoice()
                            }
                        }
                    }
                }
            }
        }
    }
}
