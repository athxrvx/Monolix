// Kuro AI sidebar.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.components
import qs.services

PopupWindow {
    id: root

    property bool opened: false
    property var barWindow: null
    property var target: null
    property string modelName: ""
    property var models: []
    property bool modelPickerOpen: false
    property string modelStatus: "Checking Ollama…"
    property string ollamaServiceStatus: "unknown"
    property bool ollamaActive: false
    property bool ollamaStateKnown: false
    property bool ollamaServiceBusy: false
    property string ollamaServiceError: ""
    property var messages: []
    property var modelMessages: []
    property var actionQueue: []
    property var activeAction: null
    property bool chatBusy: false
    property string chatError: ""
    property var pendingAction: null
    anchor.window: root.barWindow
    visible: opened
    grabFocus: true
    implicitWidth: Math.min(460, (barWindow?.width ?? 484) - Theme.popupGap * 2)
    implicitHeight: Math.max(360, Math.min(680, (barWindow?.screen?.height ?? 768) - anchor.rect.y - 16))
    color: "transparent"
    onVisibleChanged: {
        if (visible && opened) focusActiveInput();
        else if (!visible && opened && BarPopup.open && BarPopup.kind === "ai") BarPopup.close();
    }

    function toggle() { opened ? close() : open(target, barWindow) }
    function syncFromBar() {
        if (BarPopup.open && BarPopup.kind === "ai" && BarPopup.target && BarPopup.barWindow)
            open(BarPopup.target, BarPopup.barWindow);
        else if (opened)
            close();
    }
    function place() {
        if (!target || !barWindow) return;
        const p = target.mapToItem(null, target.width / 2, target.height);
        const x = Math.round(p.x - implicitWidth / 2);
        const edge = Theme.popupGap;
        const maxX = Math.max(edge, barWindow.width - implicitWidth - edge);
        anchor.rect.x = Math.max(edge, Math.min(x, maxX));
        anchor.rect.y = Math.round(p.y + Theme.popupGap);
    }
    function focusActiveInput() {
        Qt.callLater(() => {
            if (!root.opened || !root.visible) return;
            composer.forceActiveFocus();
            composer.cursorPosition = composer.length;
        });
    }
    function open(nextTarget, nextBarWindow) {
        if (nextTarget) target = nextTarget;
        if (nextBarWindow) barWindow = nextBarWindow;
        if (!target || !barWindow) return;
        place();
        opened = true;
        refreshOllamaService();
        // Recover after an Ollama restart when the model list is empty.
        if (models.length === 0) refreshModels();
        focusActiveInput();
    }
    function close() {
        opened = false;
        if (BarPopup.open && BarPopup.kind === "ai") BarPopup.close();
    }
    function refreshModels() {
        if (!ollamaStateKnown) {
            modelStatus = "Checking Ollama service…";
            refreshOllamaService();
            return;
        }
        if (!ollamaActive) {
            modelStatus = "Ollama is stopped. Turn it on above to chat.";
            return;
        }
        if (modelsProc.running) return;
        modelStatus = "Loading installed models…";
        modelsProc.command = ["curl", "-fsS", "http://127.0.0.1:11434/api/tags"];
        modelsProc.running = true;
    }
    function refreshOllamaService() {
        if (!ollamaStateProc.running) ollamaStateProc.running = true;
    }
    function toggleOllamaService() {
        if (ollamaServiceBusy) return;
        ollamaServiceError = "";
        ollamaServiceBusy = true;
        ollamaActionProc.command = ["systemctl", "--no-block", ollamaActive ? "stop" : "start", "ollama.service"];
        ollamaActionProc.running = true;
    }
    onOllamaActiveChanged: {
        if (ollamaActive) {
            modelStatus = "Ollama is starting…";
            ollamaReadyTimer.restart();
        } else if (ollamaStateKnown) {
            modelStatus = "Ollama is stopped. Turn it on above to chat.";
        }
    }
    function sendChat() {
        const prompt = composer.text.trim();
        const model = modelName.trim();
        if (!ollamaActive) {
            chatError = "Ollama is stopped. Turn it on above to chat.";
            return;
        }
        if (prompt === "") return;
        if (model === "") {
            chatError = "No model selected yet. Open Models and choose one.";
            return;
        }
        if (pendingAction !== null) {
            chatError = "Approve or cancel the pending action first.";
            return;
        }
        if (chatBusy) {
            chatError = "Ollama is still answering. Wait for it to finish.";
            return;
        }
        messages = messages.concat([{ role: "user", content: prompt }]);
        modelMessages = modelMessages.concat([{ role: "user", content: prompt }]);
        composer.text = "";
        requestChat();
    }
    function requestChat() {
        const model = modelName.trim();
        if (!ollamaActive || model === "" || chatBusy) return;
        chatBusy = true;
        chatError = "";
        const payload = JSON.stringify({
            model: model,
            messages: [{ role: "system", content: "You are Kuro, the local AI navigator built into the Kuro desktop shell. Personality: warm, sharp, concise, quietly playful, and practical. You speak like a trusted navigator: direct about tradeoffs, calm under pressure, never dramatic, and you keep answers short unless the user asks for detail. You may request only the provided allowlisted actions: theme, font, wallpaper, night light, focus mode, timers, containers, YouTube, app launching, brightness, and read-only status lookups (media, system stats, disk, weather, todos, containers, and file search). Read-only status lookups and low-risk desktop controls (theme, font, wallpaper, night light, focus mode, timers) run immediately when requested; do not ask the user to approve them or show a run-script prompt. Brightness changes, app launches, media playback, container operations, and other consequential actions require the applet's confirmation. Never invent commands, scripts, file paths, or results. Never claim an action ran before it did. After an action runs, base your reply on its returned output and exit status. If the result says no verification output was produced, report only that it exited successfully without confirming the resulting state." }].concat(modelMessages),
            stream: false,
            tools: [
                { type: "function", function: {
                    name: "kuro_set_theme",
                    description: "Change the Kuro colorscheme immediately when the user asks. This is a low-risk reversible desktop setting and does not require approval. Available ids: " + Config.kuroSchemes.map(item => item.id).join(", ") + ". rose-pine is the only light theme; every other available theme is dark. Use the id, not the display name.",
                    parameters: { type: "object", properties: {
                        theme: { type: "string", enum: Config.kuroSchemes.map(item => item.id), description: "Theme id. rose-pine is light; the rest are dark." }
                    }, required: ["theme"], additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_set_font",
                    description: "Change the UI, shell, bar, and terminal font immediately when the user asks. This is a low-risk reversible desktop setting and does not require approval. Choose one approved Nerd Font: JetBrainsMono, CaskaydiaCove, FiraCode, or Iosevka.",
                    parameters: { type: "object", properties: {
                        family: { type: "string", enum: ["JetBrainsMono Nerd Font", "CaskaydiaCove Nerd Font", "FiraCode Nerd Font", "Iosevka Nerd Font"], description: "Exact approved font family name." }
                    }, required: ["family"], additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_random_wallpaper",
                    description: "Apply a random image from the user's configured wallpaper folder immediately when the user asks. This is a low-risk reversible desktop setting and does not require approval. Only the wallpaper changes; the colorscheme stays the same.",
                    parameters: { type: "object", properties: {}, additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_night_light",
                    description: "Control night light immediately when the user asks. This is a low-risk reversible desktop setting and does not require approval. on = 4500K, warm = 3500K (best at night), cool = 5000K (best in daylight), off = stop, toggle = flip current state.",
                    parameters: { type: "object", properties: {
                        mode: { type: "string", enum: ["on", "off", "warm", "cool", "toggle"], description: "Night light mode and warmth." }
                    }, required: ["mode"], additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_focus_mode",
                    description: "Control focus mode immediately when the user asks. This is a reversible desktop setting and does not require approval. on = enable Do Not Disturb and block idle sleep; off = restore both; toggle = flip. Use it for deep work, study, or meetings.",
                    parameters: { type: "object", properties: {
                        mode: { type: "string", enum: ["on", "off", "toggle"], description: "Whether to enable, disable, or flip focus mode." }
                    }, required: ["mode"], additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_set_timer",
                    description: "Set a one-shot timer immediately when the user asks. Timers run independently, can overlap, and send a desktop notification when they finish. This does not require approval.",
                    parameters: { type: "object", properties: {
                        seconds: { type: "integer", minimum: 1, maximum: 86400, description: "Duration in seconds (1 second to 24 hours)." },
                        label: { type: "string", pattern: "^[A-Za-z0-9 _-]{0,48}$", description: "Optional short label shown in the notification; letters, numbers, spaces, _ and -." }
                    }, required: ["seconds"], additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_open_container",
                    description: "Open an existing distrobox/podman container in a floating terminal. Use the exact lowercase container name; containers must already exist. Ask for approval before using.",
                    parameters: { type: "object", properties: {
                        name: { type: "string", pattern: "^[a-z][a-z0-9_.-]{0,62}$", description: "Exact existing container name, e.g. dev." }
                    }, required: ["name"], additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_container_install",
                    description: "Install packages inside an existing container. Pick the manager that matches the distro: apt = Debian/Ubuntu, dnf = Fedora/RHEL, pacman = Arch, apk = Alpine. Ask for approval before using.",
                    parameters: { type: "object", properties: {
                        container: { type: "string", pattern: "^[a-z][a-z0-9_.-]{0,62}$", description: "Exact existing container name." },
                        manager: { type: "string", enum: ["apt", "dnf", "pacman", "apk"], description: "Package manager that matches the container distro." },
                        packages: { type: "array", items: { type: "string", pattern: "^[a-z0-9][a-z0-9+._-]{0,63}$" }, minItems: 1, maxItems: 8, description: "One to eight lowercase package names." }
                    }, required: ["container", "manager", "packages"], additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_youtube",
                    description: "Search YouTube and play the first matching video in mpv, or play a direct YouTube URL. Use this for music, trailers, tutorials, or 'play X' requests. Ask for approval before using.",
                    parameters: { type: "object", properties: {
                        query: { type: "string", minLength: 1, maxLength: 160, description: "Search terms or a full YouTube URL." }
                    }, required: ["query"], additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_open_app",
                    description: "Launch an installed desktop application. Use its short .desktop id without the suffix, for example firefox, kitty, dolphin, discord, spotify, code. Do not guess an id; ask the user if unsure. Ask for approval before using.",
                    parameters: { type: "object", properties: {
                        app: { type: "string", pattern: "^[A-Za-z0-9._-]{1,80}$", description: "Installed desktop id, with or without .desktop." }
                    }, required: ["app"], additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_brightness",
                    description: "Change screen brightness. Use a percentage from 1 to 100 for an absolute level, or up/down to step by 10 percent. Ask for approval before using.",
                    parameters: { type: "object", properties: {
                        value: { type: "string", pattern: "^(up|down|[0-9]{1,3})$", description: "'up', 'down', or a percentage from 1 to 100." }
                    }, required: ["value"], additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_media_status",
                    description: "Read-only. Report the active media player, playback state, and current track. Use when the user asks what is playing. Runs immediately without approval.",
                    parameters: { type: "object", properties: {}, additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_system_stats",
                    description: "Read-only. Report CPU load, memory usage, the warmest temperature sensor, and GPU utilization when available. Runs immediately without approval.",
                    parameters: { type: "object", properties: {}, additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_disk_usage",
                    description: "Read-only. Report filesystem usage for mounted disks. Runs immediately without approval.",
                    parameters: { type: "object", properties: {}, additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_weather",
                    description: "Read-only. Report the cached current weather and five-day forecast. Use for weather questions. Runs immediately without approval.",
                    parameters: { type: "object", properties: {}, additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_todo_list",
                    description: "Read-only. List open tasks from the user's task file, sorted by date. Runs immediately without approval.",
                    parameters: { type: "object", properties: {}, additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_container_list",
                    description: "Read-only. List podman containers and distrobox containers. Runs immediately without approval.",
                    parameters: { type: "object", properties: {}, additionalProperties: false }
                } },
                { type: "function", function: {
                    name: "kuro_find_file",
                    description: "Read-only. Find files by name under the user's home directory. Returns at most 25 matches. Use a short filename fragment. Runs immediately without approval.",
                    parameters: { type: "object", properties: {
                        query: { type: "string", minLength: 1, maxLength: 80, description: "Filename fragment, letters or numbers, one line." }
                    }, required: ["query"], additionalProperties: false }
                } }
            ]
        });
        chatProc.command = [
            "curl", "-fsS", "http://127.0.0.1:11434/api/chat",
            "-H", "Content-Type: application/json",
            "-d", payload
        ];
        chatProc.running = true;
    }
    function actionForTool(name, args) {
        const validContainer = value => /^[a-z][a-z0-9_.-]{0,62}$/.test(String(value ?? ""));
        const validPackage = value => /^[a-z0-9][a-z0-9+._-]{0,63}$/.test(String(value ?? ""));
        if (name === "kuro_set_theme") {
            const theme = Config.kuroSchemes.find(item => item.id === String(args.theme ?? ""));
            if (theme) return { name, title: "Change theme to " + theme.name, script: "ai-theme", args: [theme.id], autoRun: true };
        } else if (name === "kuro_set_font") {
            const family = String(args.family ?? "");
            if (["JetBrainsMono Nerd Font", "CaskaydiaCove Nerd Font", "FiraCode Nerd Font", "Iosevka Nerd Font"].includes(family))
                return { name, title: "Change shell, bar, and terminal font", detail: family, script: "ai-font", args: [family], autoRun: true };
        } else if (name === "kuro_random_wallpaper") {
            return { name, title: "Apply a random wallpaper", script: "ai-wallpaper", args: [Config.wallpaperDir], autoRun: true };
        } else if (name === "kuro_night_light") {
            const mode = String(args.mode ?? "");
            if (["on", "off", "warm", "cool", "toggle"].includes(mode))
                return { name, title: "Night light: " + mode, script: "ai-nightlight", args: [mode], autoRun: true };
        } else if (name === "kuro_focus_mode") {
            const mode = String(args.mode ?? "");
            if (["on", "off", "toggle"].includes(mode))
                return { name, title: "Focus mode: " + mode, script: "ai-focus", args: [mode], autoRun: true };
        } else if (name === "kuro_set_timer") {
            const seconds = Number(args.seconds);
            const label = String(args.label ?? "").trim() || "Timer";
            if (Number.isInteger(seconds) && seconds >= 1 && seconds <= 86400 &&
                label.length <= 48 && /^[A-Za-z0-9 _-]*$/.test(label))
                return { name, title: "Set a timer for " + seconds + "s", detail: label,
                         script: "ai-timer", args: ["set", String(seconds), label], autoRun: true };
        } else if (name === "kuro_open_container") {
            const container = String(args.name ?? "");
            if (validContainer(container))
                return { name, title: "Open container " + container, script: "ai-container-open",
                         args: [container], terminal: true };
        } else if (name === "kuro_container_install") {
            const container = String(args.container ?? "");
            const manager = String(args.manager ?? "");
            const packages = Array.isArray(args.packages) ? args.packages.map(item => String(item)) : [];
            if (validContainer(container) && ["apt", "dnf", "pacman", "apk"].includes(manager) &&
                packages.length >= 1 && packages.length <= 8 && packages.every(validPackage))
                return { name, title: "Install packages in " + container,
                         detail: manager + ": " + packages.join(" "), script: "ai-container-install",
                         args: [container, manager].concat(packages), terminal: true };
        } else if (name === "kuro_youtube") {
            const query = String(args.query ?? "").trim();
            if (query !== "" && query.length <= 160 && !/[\r\n]/.test(query))
                return { name, title: "Play YouTube: " + query, detail: "first search result",
                         script: "ai-youtube", args: [query] };
        } else if (name === "kuro_open_app") {
            const app = String(args.app ?? "");
            if (/^[A-Za-z0-9._-]{1,80}$/.test(app))
                return { name, title: "Open application " + app, script: "ai-open-app", args: [app] };
        } else if (name === "kuro_brightness") {
            const value = String(args.value ?? "");
            if (value === "up" || value === "down" ||
                (/^[0-9]{1,3}$/.test(value) && Number(value) >= 1 && Number(value) <= 100))
                return { name, title: "Brightness: " + value, script: "ai-brightness", args: [value] };
        } else if (name === "kuro_media_status") {
            return { name, title: "Read media status", script: "ai-media-status", args: [], readOnly: true };
        } else if (name === "kuro_system_stats") {
            return { name, title: "Read system statistics", script: "ai-stats", args: [], readOnly: true };
        } else if (name === "kuro_disk_usage") {
            return { name, title: "Read disk usage", script: "ai-disk", args: [], readOnly: true };
        } else if (name === "kuro_weather") {
            return { name, title: "Read cached weather", script: "ai-weather", args: [], readOnly: true };
        } else if (name === "kuro_todo_list") {
            return { name, title: "List open tasks", script: "ai-todo-list", args: [], readOnly: true };
        } else if (name === "kuro_container_list") {
            return { name, title: "List containers", script: "ai-container-list", args: [], readOnly: true };
        } else if (name === "kuro_find_file") {
            const query = String(args.query ?? "").trim();
            if (query !== "" && query.length <= 80 && !/[\r\n]/.test(query))
                return { name, title: "Search files: " + query, detail: "under home",
                         script: "ai-find-file", args: [query], readOnly: true };
        }
        return null;
    }

    function receiveChatResponse(result) {
        chatBusy = false;
        const modelMessage = result.message ?? {};
        const calls = modelMessage.tool_calls ?? [];
        modelMessages = modelMessages.concat([modelMessage]);
        if (calls.length > 0) {
            actionQueue = calls.map(call => {
                const fn = call.function ?? {};
                let args = fn.arguments ?? {};
                if (typeof args === "string") {
                    try { args = JSON.parse(args); } catch (e) { args = {}; }
                }
                const name = String(fn.name ?? "unknown_tool");
                return actionForTool(name, args) ?? { name, invalid: true };
            });
            processActionQueue();
            return;
        }
        messages = messages.concat([
            { role: "assistant", content: modelMessage.content ?? "Ollama returned an empty response." }
        ]);
    }

    function appendToolResult(action, content) {
        modelMessages = modelMessages.concat([{
            role: "tool", tool_name: action.name, content: String(content)
        }]);
    }

    function processActionQueue() {
        if (pendingAction !== null || activeAction !== null) return;
        if (actionQueue.length === 0) {
            chatBusy = false;
            requestChat();
            return;
        }
        const action = actionQueue[0];
        if (action.invalid) {
            actionQueue = actionQueue.slice(1);
            appendToolResult(action, "Rejected: this action is not available or its arguments were invalid.");
            processActionQueue();
            return;
        }
        if (action.readOnly === true || action.autoRun === true) {
            actionQueue = actionQueue.slice(1);
            runActionScript(action);
            return;
        }
        chatBusy = false;
        pendingAction = action;
        const prompt = "I can " + action.title + (action.detail ? " · " + action.detail : "") + ". Choose whether to run it below.";
        messages = messages.concat([{ role: "assistant", content: action.prompt || prompt }]);
    }

    function runActionScript(action) {
        if (aiActionProc.running) {
            appendToolResult(action, "Could not run: another Kuro script is already running.");
            processActionQueue();
            return;
        }
        activeAction = action;
        chatBusy = true;
        chatError = "";
        aiActionProc.outputText = "";
        aiActionProc.errorText = "";
        aiActionProc.command = [Config.home + "/.config/quickshell/shell/bin/skills/" + action.script]
            .concat(action.args ?? []);
        aiActionProc.running = true;
    }

    function approveAction() {
        if (!pendingAction) return;
        const action = pendingAction;
        pendingAction = null;
        actionQueue = actionQueue.slice(1);
        if (action.terminal === true) {
            Quickshell.execDetached(Config.popupTerminal.concat([
                Config.home + "/.config/quickshell/shell/bin/skills/" + action.script
            ], action.args ?? []));
            appendToolResult(action, "An interactive terminal was opened for this action. Its completion is not yet confirmed.");
            messages = messages.concat([{ role: "assistant", content: "Opened a terminal for that action. Its result will appear there." }]);
            processActionQueue();
            return;
        }
        runActionScript(action);
    }

    function rejectAction() {
        if (!pendingAction) return;
        const action = pendingAction;
        pendingAction = null;
        actionQueue = actionQueue.slice(1);
        appendToolResult(action, "The user declined this action; it was not run.");
        messages = messages.concat([{ role: "assistant", content: "Cancelled; I did not run it." }]);
        processActionQueue();
    }

    Timer {
    }

    Timer {
        interval: 4000
        repeat: true
        running: root.opened || root.ollamaServiceStatus === "activating"
        onTriggered: root.refreshOllamaService()
    }

    Timer {
        id: ollamaReadyTimer
        interval: 1200
        onTriggered: if (root.ollamaActive) root.refreshModels()
    }

    Process {
        id: ollamaStateProc
        command: ["systemctl", "show", "--property=ActiveState", "--value", "ollama.service"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.ollamaServiceStatus = text.trim() || "unknown";
                root.ollamaStateKnown = true;
                root.ollamaActive = root.ollamaServiceStatus === "active";
                if (root.ollamaActive && root.models.length === 0)
                    root.refreshModels();
                if (!root.ollamaActive)
                    root.modelStatus = root.ollamaServiceStatus === "activating"
                        ? "Ollama is starting…" : "Ollama is stopped. Turn it on above to chat.";
            }
        }
    }

    Process {
        id: ollamaActionProc
        stderr: StdioCollector { onStreamFinished: root.ollamaServiceError = text.trim() }
        onExited: (exitCode, status) => {
            root.ollamaServiceBusy = false;
            if (exitCode !== 0) {
                root.ollamaServiceError = root.ollamaServiceError || "Could not change Ollama service state.";
            }
            root.refreshOllamaService();
        }
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
        property string outputText: ""
        property string errorText: ""
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: aiActionProc.outputText = text
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: aiActionProc.errorText = text
        }
        onExited: exitCode => {
            const action = root.activeAction;
            root.activeAction = null;
            root.chatBusy = false;
            if (!action) return;

            const output = aiActionProc.outputText.trim();
            const error = aiActionProc.errorText.trim();
            const ok = exitCode === 0;
            const detail = ok
                ? (output || "No verification output was produced.")
                : (error || output || "The script did not report a reason.");
            root.appendToolResult(action,
                (ok ? "Script exited successfully." : "Script failed with exit status " + exitCode + ".")
                + "\n" + detail.slice(0, 4000));
            if (!ok) root.chatError = action.title + " failed (exit " + exitCode + ").";
            root.processActionQueue();
        }
    }


    Rectangle {
        id: surface
        anchors.fill: parent
        color: Theme.bg
        border.width: 1
        border.color: Theme.accent
        clip: true

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

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 50
                    color: Theme.bgAlt
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "OLLAMA SERVICE"
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 10
                                font.letterSpacing: 1
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.ollamaServiceError !== "" ? root.ollamaServiceError
                                    : root.ollamaServiceBusy ? "Changing service state…"
                                    : root.ollamaServiceStatus === "activating" ? "Starting local model service…"
                                    : root.ollamaActive ? "Running · RTX 4050 available"
                                    : "Stopped · GPU stays idle"
                                color: root.ollamaServiceError !== "" ? Theme.danger : Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        Switch {
                            checked: root.ollamaActive || root.ollamaServiceStatus === "activating"
                            enabled: !root.ollamaServiceBusy && root.ollamaServiceStatus !== "activating"
                            onToggled: root.toggleOllamaService()
                        }
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
                    currentIndex: 0

                    ColumnLayout {
                        spacing: 10

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

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 210
                                    visible: root.messages.length === 0
                                    spacing: 8

                                    Item { Layout.fillHeight: true }

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: 48
                                        Layout.preferredHeight: 48
                                        color: Theme.surface
                                        border.color: Theme.border
                                        Text {
                                            anchors.centerIn: parent
                                            text: Icons.bot
                                            color: Theme.accent
                                            font.family: Theme.iconFont
                                            font.pixelSize: 26
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: root.modelName === "" ? "Choose a model to begin" : "Ready when you are"
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: 13
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 24
                                        Layout.rightMargin: 24
                                        text: "Your conversation stays with your local Ollama model."
                                        color: Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.Wrap
                                    }

                                    Item { Layout.fillHeight: true }
                                }

                                Repeater {
                                    model: root.messages
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool fromUser: modelData.role === "user"
                                        Layout.fillWidth: true
                                        implicitHeight: messageLayout.implicitHeight + 20
                                        color: fromUser ? Theme.surface : Theme.bgAlt
                                        border.color: Theme.border
                                        border.width: 1
                                        radius: 0

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: 2
                                            color: fromUser ? Theme.accent : Theme.border
                                        }

                                        ColumnLayout {
                                            id: messageLayout
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 10
                                            anchors.topMargin: 9
                                            anchors.bottomMargin: 9
                                            spacing: 6

                                            RowLayout {
                                                spacing: 6
                                                Text {
                                                    text: fromUser ? Icons.user : Icons.bot
                                                    color: fromUser ? Theme.accent : Theme.muted
                                                    font.family: Theme.iconFont
                                                    font.pixelSize: 12
                                                }
                                                Text {
                                                    text: fromUser ? "YOU" : "KURO"
                                                    color: fromUser ? Theme.accent : Theme.muted
                                                    font.family: Theme.font
                                                    font.pixelSize: 9
                                                    font.letterSpacing: 1
                                                }
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
                                            text: "Confirm to continue with this action."
                                            color: Theme.muted
                                            font.family: Theme.font
                                            font.pixelSize: 10
                                            wrapMode: Text.Wrap
                                        }
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Item { Layout.fillWidth: true }
                                            TextButton { text: "Cancel"; onClicked: root.rejectAction() }
                                            TextButton { text: "Confirm action"; primary: true; onClicked: root.approveAction() }
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

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: root.modelPickerOpen
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: root.modelStatus
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            Repeater {
                                model: root.models
                                delegate: TextButton {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    text: modelData
                                    sharp: true
                                    onClicked: {
                                        root.modelName = modelData;
                                        root.modelPickerOpen = false;
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            color: Theme.surface
                            border.width: 1
                            border.color: composer.activeFocus ? Theme.accent : Theme.border
                            clip: true

                            TextEdit {
                                id: composer
                                focus: root.opened
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                anchors.topMargin: 36
                                anchors.bottomMargin: 8
                                color: Theme.text
                                selectionColor: Theme.selectionBg
                                selectedTextColor: Theme.selectionFg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                wrapMode: TextEdit.Wrap
                                selectByMouse: true
                                clip: true
                                TapHandler {
                                    gesturePolicy: TapHandler.WithinBounds
                                    onTapped: composer.forceActiveFocus()
                                }
                                Keys.onPressed: event => {
                                    const isEnter = event.key === Qt.Key_Return || event.key === Qt.Key_Enter;
                                    if (isEnter && !(event.modifiers & Qt.ShiftModifier)) {
                                        root.sendChat();
                                        event.accepted = true;
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            TextButton {
                                text: Icons.cpu
                                sharp: true
                                flat: root.modelPickerOpen
                                onClicked: {
                                    root.modelPickerOpen = !root.modelPickerOpen;
                                    if (root.models.length === 0) root.refreshModels();
                                }
                            }
                            TextButton {
                                text: "Clear"
                                sharp: true
                                enabled: !root.chatBusy && root.pendingAction === null
                                onClicked: {
                                    root.messages = [];
                                    root.modelMessages = [];
                                    root.actionQueue = [];
                                    root.chatError = "";
                                }
                            }
                            Item { Layout.fillWidth: true }
                            TextButton {
                                text: root.chatBusy ? "Thinking…" : "Send"
                                primary: true
                                sharp: true
                                enabled: !root.chatBusy && root.pendingAction === null && root.modelName.trim() !== "" && composer.text.trim() !== ""
                                onClicked: root.sendChat()
                            }
                        }
                    }

                                    // AI chat and actions remain in the active sidebar.
}
            }
        }
    }
}
