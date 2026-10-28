pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.misc
import qs.config
import qs.services
import qs.utils
import qs.modules.controlcenter
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    anchors.fill: parent

    property string activePage: "overview"
    property string processSearch: ""
    property string processView: "apps"
    property string newGameName: ""
    property string newGameCommand: ""
    property string gameStatus: qsTr("Your game library is ready.")
    property string wallpaperStatus: ""
    property string activeWallpaperUrl: ""
    property string activeWallpaperPath: ""
    property string wallpaperSearch: ""
    property string wallpaperSource: "unsplash"
    property bool wallpaperSearching: false
    property var wallhavenWallpapers: []
    property string monoOutput: qsTr("Mono system tools are ready.")
    property bool monoBusy: false

    readonly property real gpuFraction: Math.min(1, SystemUsage.gpuPerc > 1 ? SystemUsage.gpuPerc / 100 : SystemUsage.gpuPerc)
    readonly property var installedGames: [...DesktopEntries.applications.values]
        .filter(app => (app.categories || []).some(category => String(category).toLowerCase().includes("game")))
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var processApps: {
        const processes = SysMonitorService.processes || [];
        if (processes.length === 0)
            return [];
        const grouped = {};
        for (let i = 0; i < processes.length; i++) {
            const process = processes[i];
            const fullCommand = String(process.fullCommand || process.command || qsTr("Process"));
            const executable = String(process.command || fullCommand.split(/\s+/)[0].split("/").pop() || qsTr("Process"));
            const key = executable.toLowerCase();
            if (!grouped[key])
                grouped[key] = { command: executable, cpu: 0, memoryKB: 0, memoryPercent: 0, pids: [], processes: [] };
            grouped[key].cpu += Number(process.cpu) || 0;
            grouped[key].memoryKB += Number(process.memoryKB) || 0;
            grouped[key].memoryPercent += Number(process.memoryPercent) || 0;
            grouped[key].pids.push(Number(process.pid));
            grouped[key].processes.push(process);
        }
        const result = Object.values(grouped);
        result.sort((a, b) => b.memoryKB - a.memoryKB);
        return result;
    }
    readonly property var filteredApps: {
        const search = processSearch.trim().toLowerCase();
        if (!search)
            return processApps;
        const result = [];
        for (let i = 0; i < processApps.length; i++) {
            if (processApps[i].command.toLowerCase().includes(search))
                result.push(processApps[i]);
        }
        return result;
    }
    readonly property var filteredProcesses: {
        const search = processSearch.trim().toLowerCase();
        const processes = SysMonitorService.processes || [];
        if (!search)
            return processes;
        const result = [];
        for (let i = 0; i < processes.length; i++) {
            const proc = processes[i];
            const text = String(proc.fullCommand || proc.command || "").toLowerCase();
            if (text.includes(search))
                result.push(proc);
        }
        return result;
    }
    readonly property var onlineWallpapers: [
        { id: "alpine-lake", name: qsTr("Alpine lake"), category: qsTr("Nature"), url: "https://images.unsplash.com/photo-1470770841072-f978cf4d019e?w=1100&h=700&fit=crop&auto=format&q=88" },
        { id: "forest-light", name: qsTr("Forest light"), category: qsTr("Nature"), url: "https://images.unsplash.com/photo-1448375240586-882707db888b?w=1100&h=700&fit=crop&auto=format&q=88" },
        { id: "blue-hour", name: qsTr("Blue hour"), category: qsTr("Mountains"), url: "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=1100&h=700&fit=crop&auto=format&q=88" },
        { id: "coastline", name: qsTr("Open water"), category: qsTr("Ocean"), url: "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=1100&h=700&fit=crop&auto=format&q=88" },
        { id: "mountain-range", name: qsTr("Mountain range"), category: qsTr("Mountains"), url: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1100&h=700&fit=crop&auto=format&q=88" },
        { id: "golden-field", name: qsTr("Golden field"), category: qsTr("Landscape"), url: "https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?w=1100&h=700&fit=crop&auto=format&q=88" }
    ]
    readonly property var visibleWallpapers: wallpaperSource === "wallhaven" ? wallhavenWallpapers
        : wallpaperSource === "unsplash" ? onlineWallpapers.filter(wallpaper => !wallpaperSearch.trim()
            || `${wallpaper.name} ${wallpaper.category}`.toLowerCase().includes(wallpaperSearch.trim().toLowerCase()))
        : []

    function formatBytes(value: real): string {
        if (value >= 1024 ** 3)
            return `${(value / (1024 ** 3)).toFixed(1)} GiB`;
        if (value >= 1024 ** 2)
            return `${(value / (1024 ** 2)).toFixed(0)} MiB`;
        return `${(value / 1024).toFixed(0)} KiB`;
    }

    function formatRate(value: real): string {
        if (value >= 1024 ** 2)
            return `${(value / (1024 ** 2)).toFixed(1)} MiB/s`;
        if (value >= 1024)
            return `${(value / 1024).toFixed(0)} KiB/s`;
        return `${Math.max(0, value).toFixed(0)} B/s`;
    }

    function memorySummary(): string {
        const used = SystemUsage.formatKib(SystemUsage.memUsed);
        const total = SystemUsage.formatKib(SystemUsage.memTotal);
        return `${used.value.toFixed(1)} / ${Math.floor(total.value)} ${total.unit}`;
    }

    function storageSummary(): string {
        let used = 0;
        let total = 0;
        for (const disk of SystemUsage.disks) {
            used += disk.used;
            total += disk.total;
        }
        return SystemUsage.disks.length > 0
            ? `${formatBytes(used * 1024)} / ${formatBytes(total * 1024)}`
            : qsTr("No mounted storage");
    }

    function batterySummary(): string {
        const device = UPower.displayDevice;
        if (!device.isLaptopBattery)
            return qsTr("Battery unavailable");
        if (device.state === UPowerDeviceState.FullyCharged)
            return qsTr("Fully charged");
        if ([UPowerDeviceState.Charging, UPowerDeviceState.PendingCharge].includes(device.state))
            return qsTr("Charging");
        const seconds = device.timeToEmpty;
        if (seconds <= 0)
            return qsTr("On battery");
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours > 0 ? qsTr("%1h %2m remaining").arg(hours).arg(minutes) : qsTr("%1m remaining").arg(minutes);
    }

    function refreshSystem(): void {
        SysMonitorService.updateAllStats();
    }

    onActivePageChanged: {
        if (activePage === "processes")
            Qt.callLater(() => root.refreshSystem());
        else if (activePage === "mono" && monoOutput === qsTr("Mono system tools are ready.")) {
            monoBusy = true;
            monoProcess.command = ["mono", "status"];
            monoProcess.running = true;
        }
    }

    function sortProcesses(by: string): void {
        if (SysMonitorService.sortBy === by)
            SysMonitorService.toggleSortOrder();
        else
            SysMonitorService.setSortBy(by);
    }

    function runMono(args: list<string>, label: string): void {
        Quickshell.execDetached(["kitty", "--title", `Mono — ${label}`, "-e", "mono", ...args]);
    }

    function openFolder(path: string): void {
        pendingFolder = path;
        folderProcess.command = ["mkdir", "-p", path];
        folderProcess.running = true;
    }

    property string pendingFolder: ""

    function downloadWallpaper(wallpaper: var): void {
        activeWallpaperUrl = wallpaper.url;
        const extension = (wallpaper.url.match(/\.(png|jpe?g|webp)(?:\?|$)/i) || [null, "jpg"])[1];
        activeWallpaperPath = `${Paths.wallsdir}/online/${wallpaper.id}.${extension}`;
        wallpaperStatus = qsTr("Preparing %1…").arg(wallpaper.name);
        wallpaperDirectoryProcess.command = ["mkdir", "-p", `${Paths.wallsdir}/online`];
        wallpaperDirectoryProcess.running = true;
    }

    function browseWallpaperSource(source: string): void {
        wallpaperSource = source;
        const query = encodeURIComponent(wallpaperSearch.trim());
        const urls = {
            unsplash: query.length ? `https://unsplash.com/s/photos/${query}` : "https://unsplash.com/wallpapers",
            wallhaven: query.length ? `https://wallhaven.cc/search?q=${query}&categories=111&purity=100` : "https://wallhaven.cc/toplist",
            fourk: query.length ? `https://4kwallpapers.com/search/?q=${query}` : "https://4kwallpapers.com/most-popular-4k-wallpapers/"
        };
        if (source === "wallhaven") {
            wallpaperSearching = true;
            wallpaperStatus = qsTr("Searching Wallhaven…");
            wallhavenSearchProcess.command = ["curl", "--fail", "--location", "--silent", "--show-error",
                `https://wallhaven.cc/api/v1/search?categories=111&purity=100&sorting=toplist&q=${query}`];
            wallhavenSearchProcess.running = true;
            return;
        }
        if (source === "unsplash") {
            wallpaperStatus = visibleWallpapers.length > 0 ? qsTr("Showing featured Unsplash wallpapers.") : qsTr("No featured wallpapers match that search. Open Unsplash to explore more.");
            return;
        }
        wallpaperStatus = qsTr("Opening %1 in your browser…").arg(source === "fourk" ? "4K Wallpapers" : "Unsplash");
        Quickshell.execDetached(["systemd-run", "--user", "--scope", "--collect", "--quiet", "--", "xdg-open", urls[source] || urls.unsplash]);
    }

    function parseWallhavenResults(output: string, exitCode: int): void {
        wallpaperSearching = false;
        if (exitCode !== 0) {
            wallpaperStatus = qsTr("Wallhaven search failed. Check your connection and try again.");
            wallhavenWallpapers = [];
            return;
        }
        try {
            const payload = JSON.parse(output);
            wallhavenWallpapers = (payload.data || []).map(item => ({
                id: item.id,
                name: item.category || qsTr("Wallhaven wallpaper"),
                category: `${item.resolution || ""} · Wallhaven`,
                url: item.path,
                thumbnail: item.thumbs?.large || item.path
            }));
            wallpaperStatus = wallhavenWallpapers.length > 0
                ? qsTr("Showing %1 safe-for-work results from Wallhaven.").arg(wallhavenWallpapers.length)
                : qsTr("No Wallhaven results found. Try another search.");
        } catch (error) {
            wallhavenWallpapers = [];
            wallpaperStatus = qsTr("Wallhaven returned an unreadable result. Try again.");
            console.warn("Could not parse Wallhaven results:", error);
        }
    }

    function openWallpaperWebsite(): void {
        const query = encodeURIComponent(wallpaperSearch.trim());
        const urls = {
            unsplash: query.length ? `https://unsplash.com/s/photos/${query}` : "https://unsplash.com/wallpapers",
            wallhaven: query.length ? `https://wallhaven.cc/search?q=${query}&categories=111&purity=100` : "https://wallhaven.cc/toplist",
            fourk: query.length ? `https://4kwallpapers.com/search/?q=${query}` : "https://4kwallpapers.com/most-popular-4k-wallpapers/"
        };
        Quickshell.execDetached(["systemd-run", "--user", "--scope", "--collect", "--quiet", "--", "xdg-open", urls[wallpaperSource] || urls.unsplash]);
    }

    Ref { service: SystemUsage }
    Ref { service: SysMonitorService }

    Process {
        id: monoProcess
        running: false
        command: ["mono", "status"]
        stdout: StdioCollector { onStreamFinished: root.monoOutput = text.trim() }
        stderr: StdioCollector { onStreamFinished: root.monoOutput = text.trim() }
        onExited: code => {
            root.monoBusy = false;
            if (code !== 0 && root.monoOutput.length === 0)
                root.monoOutput = qsTr("Mono exited with code %1.").arg(code);
        }
    }

    Process {
        id: folderProcess
        running: false
        onExited: code => {
            if (code === 0)
                Quickshell.execDetached(["systemd-run", "--user", "--scope", "--collect", "--quiet", "--", "xdg-open", root.pendingFolder]);
            else
                root.gameStatus = qsTr("Could not open that folder.");
        }
    }

    Process {
        id: wallpaperDirectoryProcess
        command: []
        running: false
        onExited: code => {
            if (code === 0) {
                root.wallpaperStatus = qsTr("Downloading wallpaper…");
                wallpaperDownloadProcess.running = true;
            } else {
                root.wallpaperStatus = qsTr("Could not prepare the wallpaper folder.");
            }
        }
    }

    Process {
        id: wallpaperDownloadProcess
        running: false
        command: ["curl", "--fail", "--location", "--silent", "--show-error", root.activeWallpaperUrl, "--output", root.activeWallpaperPath]
        onExited: code => {
            if (code === 0) {
                root.wallpaperStatus = qsTr("Applying wallpaper…");
                Wallpapers.setWallpaper(root.activeWallpaperPath);
                root.wallpaperStatus = qsTr("Wallpaper applied.");
            } else {
                root.wallpaperStatus = qsTr("Download failed. Check your connection and try again.");
            }
        }
        stderr: SplitParser { onRead: data => console.warn("Online wallpaper download:", data) }
    }

    Process {
        id: wallhavenSearchProcess
        running: false
        command: []
        property string output: ""
        stdout: StdioCollector { onStreamFinished: wallhavenSearchProcess.output = text }
        onExited: code => root.parseWallhavenResults(output, code)
        stderr: SplitParser { onRead: data => console.warn("Wallhaven search:", data) }
    }

    RowLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.md

        StyledRect {
            id: sidebar
            Layout.fillHeight: true
            Layout.preferredWidth: 220
            Layout.minimumWidth: 190
            radius: Appearance.rounding.large
            color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Appearance.padding.md
                spacing: Appearance.spacing.sm

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.padding.xs
                    spacing: Appearance.spacing.sm
                    StyledClippingRect {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: Appearance.rounding.medium
                        color: Colours.palette.m3primaryContainer
                        MaterialIcon { anchors.centerIn: parent; text: "sports_esports"; color: Colours.palette.m3onPrimaryContainer; font.pointSize: Appearance.font.size.titleMedium }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.xs
                        StyledText { text: qsTr("Monohub"); font.pointSize: Appearance.font.size.titleMedium; font.weight: 700 }
                        StyledText { text: qsTr("DESKTOP HUB"); color: Colours.palette.m3onSurfaceVariant; font.pointSize: Appearance.font.size.labelSmall; font.weight: 600; font.letterSpacing: 1.1 }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.sm
                    Layout.bottomMargin: Appearance.spacing.xs
                    implicitHeight: 1
                    color: Colours.palette.m3outlineVariant
                    opacity: 0.45
                }

                StyledText {
                    Layout.leftMargin: Appearance.padding.sm
                    Layout.topMargin: Appearance.spacing.sm
                    text: qsTr("WORKSPACE")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.labelSmall
                    font.weight: 600
                    font.letterSpacing: 1.1
                }

                Repeater {
                    model: [
                        { id: "overview", label: qsTr("Overview"), icon: "dashboard" },
                        { id: "processes", label: qsTr("Processes"), icon: "monitor_heart" },
                        { id: "games", label: qsTr("My games"), icon: "sports_esports" },
                        { id: "wallpapers", label: qsTr("Wallpapers"), icon: "wallpaper" },
                        { id: "mono", label: qsTr("Mono tools"), icon: "terminal" }
                    ]
                    delegate: StyledRect {
                        id: navItem
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: Appearance.rounding.full
                        color: root.activePage === modelData.id ? Colours.palette.m3secondaryContainer : "transparent"
                        Behavior on color { CAnim {} }

                        StateLayer {
                            color: root.activePage === navItem.modelData.id ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            function onClicked(): void { root.activePage = navItem.modelData.id; }
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.padding.md
                            anchors.rightMargin: Appearance.padding.sm
                            spacing: Appearance.spacing.md
                            MaterialIcon {
                                text: navItem.modelData.icon
                                color: root.activePage === navItem.modelData.id ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                fill: root.activePage === navItem.modelData.id ? 1 : 0
                                font.pointSize: Appearance.font.size.bodyLarge
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: navItem.modelData.label
                                color: root.activePage === navItem.modelData.id ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.bodyMedium
                                font.weight: root.activePage === navItem.modelData.id ? Font.DemiBold : Font.Normal
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Colours.palette.m3outlineVariant
                    opacity: 0.45
                }
                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("Refresh system data")
                    type: TextButton.Tonal
                    onClicked: root.refreshSystem()
                }
            }
        }

    StyledFlickable {
        id: flickable
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumWidth: 0
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        StyledScrollBar.vertical: StyledScrollBar { flickable: flickable }

        ColumnLayout {
            id: content
            width: flickable.width
            spacing: Appearance.spacing.lg

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.xs
                    StyledText {
                        text: root.activePage === "overview" ? qsTr("Overview")
                            : root.activePage === "processes" ? qsTr("Processes")
                            : root.activePage === "games" ? qsTr("My games")
                            : root.activePage === "mono" ? qsTr("Mono tools") : qsTr("Wallpapers")
                        font.pointSize: Appearance.font.size.headlineSmall
                        font.weight: 600
                    }
                }
            }

            // Dashboard overview
            ColumnLayout {
                visible: root.activePage === "overview"
                Layout.fillWidth: true
                spacing: Appearance.spacing.lg

                GridLayout {
                    Layout.fillWidth: true
                    columns: width >= 850 ? 3 : 2
                    rowSpacing: Appearance.spacing.md
                    columnSpacing: Appearance.spacing.md
                    MetricCard { Layout.fillWidth: true; title: qsTr("Processor"); icon: "memory"; value: `${Math.round(SystemUsage.cpuPerc * 100)}%`; detail: SystemUsage.cpuName || qsTr("CPU usage"); progress: SystemUsage.cpuPerc; accent: Colours.palette.m3primary }
                    MetricCard { Layout.fillWidth: true; title: qsTr("Graphics"); icon: "desktop_windows"; value: `${Math.round(root.gpuFraction * 100)}%`; detail: SystemUsage.gpuName || qsTr("GPU usage"); progress: root.gpuFraction; accent: Colours.palette.m3secondary }
                    MetricCard { Layout.fillWidth: true; title: qsTr("Memory"); icon: "memory_alt"; value: `${Math.round(SystemUsage.memPerc * 100)}%`; detail: root.memorySummary(); progress: SystemUsage.memPerc; accent: Colours.palette.m3tertiary }
                    MetricCard { Layout.fillWidth: true; title: qsTr("Storage"); icon: "hard_disk"; value: `${Math.round(SystemUsage.storagePerc * 100)}%`; detail: root.storageSummary(); progress: SystemUsage.storagePerc; accent: Colours.palette.m3primary }
                    MetricCard { Layout.fillWidth: true; title: qsTr("Network"); icon: "swap_vert"; value: root.formatRate(SysMonitorService.networkRxRate); detail: qsTr("Upload %1").arg(root.formatRate(SysMonitorService.networkTxRate)); progress: Math.min(1, SysMonitorService.networkRxRate / (50 * 1024 * 1024)); accent: Colours.palette.m3secondary }
                    MetricCard { Layout.fillWidth: true; title: qsTr("Battery"); icon: UPower.displayDevice.state === UPowerDeviceState.Charging ? "battery_charging_full" : "battery_full"; value: UPower.displayDevice.isLaptopBattery ? `${Math.round(UPower.displayDevice.percentage * 100)}%` : "—"; detail: root.batterySummary(); progress: UPower.displayDevice.isLaptopBattery ? UPower.displayDevice.percentage : 0; accent: Colours.palette.m3tertiary }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: Appearance.spacing.lg

                    SectionContainer {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        alignTop: true
                        contentSpacing: Appearance.spacing.md
                        RowLayout {
                            Layout.fillWidth: true
                            StyledText { Layout.fillWidth: true; text: qsTr("Live activity"); font.pointSize: Appearance.font.size.titleMedium; font.weight: 600 }
                            MaterialIcon { text: "swap_vert"; color: Colours.palette.m3secondary }
                        }
                        InfoRow { label: qsTr("Download"); value: root.formatRate(SysMonitorService.networkRxRate) }
                        InfoRow { label: qsTr("Upload"); value: root.formatRate(SysMonitorService.networkTxRate) }
                        InfoRow { label: qsTr("Disk read"); value: root.formatRate(SysMonitorService.diskReadRate) }
                        InfoRow { label: qsTr("Disk write"); value: root.formatRate(SysMonitorService.diskWriteRate) }
                    }

                    SectionContainer {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        alignTop: true
                        contentSpacing: Appearance.spacing.md
                        RowLayout {
                            Layout.fillWidth: true
                            StyledText { Layout.fillWidth: true; text: qsTr("System details"); font.pointSize: Appearance.font.size.titleMedium; font.weight: 600 }
                            MaterialIcon { text: "info"; color: Colours.palette.m3primary }
                        }
                        InfoRow { label: qsTr("Device"); value: SysMonitorService.hostname || SysMonitor.system.hostname || "—" }
                        InfoRow { label: qsTr("Kernel"); value: SysMonitorService.kernelVersion || SysMonitor.system.kernel || "—" }
                        InfoRow { label: qsTr("Load average"); value: SysMonitorService.loadAverage || SysMonitor.system.loadavg || "—" }
                    }
                }

            }

            // Resource-style app and process manager.
            ColumnLayout {
                visible: root.activePage === "processes"
                Layout.fillWidth: true
                spacing: Appearance.spacing.lg

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        StyledText { text: qsTr("%1 processes · live system usage").arg(SysMonitorService.processCount); color: Colours.palette.m3onSurfaceVariant }
                    }
                    TextButton { text: qsTr("Refresh"); type: TextButton.Tonal; onClicked: root.refreshSystem() }
                }

                SectionContainer {
                    Layout.fillWidth: true
                    alignTop: true
                    radius: Appearance.rounding.large
                    contentSpacing: Appearance.spacing.md

                    RowLayout {
                        Layout.fillWidth: true
                        StyledRect {
                            id: processViewSwitch
                            Layout.preferredWidth: 126
                            implicitHeight: 40
                            radius: Appearance.rounding.full
                            property bool checked: root.processView === "apps"
                            color: checked ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
                            StateLayer {
                                function onClicked(): void { root.processView = "apps"; }
                            }
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.sm
                                MaterialIcon { text: "apps"; color: processViewSwitch.checked ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant }
                                StyledText { text: qsTr("Apps"); color: processViewSwitch.checked ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant; font.weight: processViewSwitch.checked ? 600 : Font.Normal }
                            }
                        }
                    StyledRect {
                        Layout.preferredWidth: 126
                        implicitHeight: 40
                        radius: Appearance.rounding.full
                        color: root.processView === "processes" ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
                        StateLayer { function onClicked(): void { root.processView = "processes"; } }
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.sm
                            MaterialIcon { text: "memory"; color: root.processView === "processes" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant }
                            StyledText { text: qsTr("Processes"); color: root.processView === "processes" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant; font.weight: root.processView === "processes" ? 600 : Font.Normal }
                        }
                    }
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: Appearance.rounding.full
                        color: Colours.palette.m3surfaceContainerHigh
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.padding.md
                            anchors.rightMargin: Appearance.padding.md
                            MaterialIcon { text: "search"; color: Colours.palette.m3onSurfaceVariant }
                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: root.processView === "apps" ? qsTr("Search apps") : qsTr("Search processes")
                                text: root.processSearch
                                onTextEdited: text => root.processSearch = text
                            }
                        }
                    }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Appearance.padding.md
                    Layout.rightMargin: Appearance.padding.md
                    StyledText { Layout.fillWidth: true; text: root.processView === "apps" ? qsTr("App") : qsTr("Process"); color: Colours.palette.m3onSurfaceVariant; font.pointSize: Appearance.font.size.labelMedium }
                    StyledText { Layout.preferredWidth: 112; text: qsTr("Memory"); horizontalAlignment: Text.AlignRight; color: Colours.palette.m3onSurfaceVariant; font.pointSize: Appearance.font.size.labelMedium }
                    StyledText { Layout.preferredWidth: 78; text: qsTr("Processor"); horizontalAlignment: Text.AlignRight; color: Colours.palette.m3onSurfaceVariant; font.pointSize: Appearance.font.size.labelMedium }
                    StyledText { Layout.preferredWidth: 54; text: qsTr("GPU"); horizontalAlignment: Text.AlignRight; color: Colours.palette.m3onSurfaceVariant; font.pointSize: Appearance.font.size.labelMedium }
                    Item { Layout.preferredWidth: 44 }
                }

                SectionContainer {
                    Layout.fillWidth: true
                    alignTop: true
                    radius: Appearance.rounding.large
                    contentSpacing: Appearance.spacing.xs
                    Repeater {
                        model: root.processView === "apps" ? root.filteredApps : root.filteredProcesses
                        delegate: ProcessListRow { required property var modelData; Layout.fillWidth: true; itemData: modelData; appMode: root.processView === "apps" }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: SysMonitorService.processes.length === 0
                        text: qsTr("No processes found. Refresh to scan the running system.")
                        color: Colours.palette.m3onSurfaceVariant
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: SysMonitorService.processes.length > 0 && (root.processView === "apps" ? root.filteredApps.length === 0 : root.filteredProcesses.length === 0)
                        text: qsTr("Nothing matches your search.")
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            // Dedicated Mono page for configuration builds and system housekeeping.
            ColumnLayout {
                visible: root.activePage === "mono"
                Layout.fillWidth: true
                spacing: Appearance.spacing.lg

                GridLayout {
                    Layout.fillWidth: true
                    columns: width >= 760 ? 2 : 1
                    rowSpacing: Appearance.spacing.lg
                    columnSpacing: Appearance.spacing.lg

                    SectionContainer {
                        Layout.fillWidth: true
                        alignTop: true
                        radius: Appearance.rounding.large
                        contentSpacing: Appearance.spacing.md
                        RowLayout {
                            Layout.fillWidth: true
                            MaterialIcon { text: "construction"; color: Colours.palette.m3primary }
                            StyledText { Layout.fillWidth: true; text: qsTr("Build and apply"); font.pointSize: Appearance.font.size.titleMedium; font.weight: 600 }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            TextButton { Layout.fillWidth: true; text: qsTr("Home Manager"); type: TextButton.Tonal; onClicked: root.runMono(["home"], "Home Manager") }
                            TextButton { Layout.fillWidth: true; text: qsTr("System sync"); type: TextButton.Filled; onClicked: root.runMono(["sync"], "System sync") }
                        }
                    }

                    SectionContainer {
                        Layout.fillWidth: true
                        alignTop: true
                        radius: Appearance.rounding.large
                        contentSpacing: Appearance.spacing.md
                        RowLayout {
                            Layout.fillWidth: true
                            MaterialIcon { text: "system_update"; color: Colours.palette.m3secondary }
                            StyledText { Layout.fillWidth: true; text: qsTr("Flake updates"); font.pointSize: Appearance.font.size.titleMedium; font.weight: 600 }
                        }
                        TextButton { text: qsTr("Update inputs"); type: TextButton.Tonal; onClicked: root.runMono(["update"], "Flake update") }
                    }

                    SectionContainer {
                        Layout.fillWidth: true
                        alignTop: true
                        radius: Appearance.rounding.large
                        contentSpacing: Appearance.spacing.md
                        RowLayout {
                            Layout.fillWidth: true
                            MaterialIcon { text: "cleaning_services"; color: Colours.palette.m3tertiary }
                            StyledText { Layout.fillWidth: true; text: qsTr("Housekeeping"); font.pointSize: Appearance.font.size.titleMedium; font.weight: 600 }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            TextButton { Layout.fillWidth: true; text: qsTr("Clean home generations"); type: TextButton.Tonal; onClicked: root.runMono(["clean"], "Clean Home Manager generations") }
                            TextButton { Layout.fillWidth: true; text: qsTr("Clean system generations"); type: TextButton.Text; onClicked: root.runMono(["clean", "--system"], "Clean system generations") }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            TextButton { Layout.fillWidth: true; text: qsTr("Collect user store data"); type: TextButton.Text; onClicked: root.runMono(["gc"], "Nix garbage collection") }
                            TextButton { Layout.fillWidth: true; text: qsTr("Collect system store data"); type: TextButton.Text; onClicked: root.runMono(["gc", "--system"], "System Nix garbage collection") }
                        }
                    }

                    SectionContainer {
                        Layout.fillWidth: true
                        alignTop: true
                        radius: Appearance.rounding.large
                        contentSpacing: Appearance.spacing.md
                        RowLayout {
                            Layout.fillWidth: true
                            MaterialIcon { text: "deployed_code"; color: Colours.palette.m3primary }
                            StyledText { Layout.fillWidth: true; text: qsTr("Generations and diagnostics"); font.pointSize: Appearance.font.size.titleMedium; font.weight: 600 }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            TextButton { Layout.fillWidth: true; text: qsTr("Generation history"); type: TextButton.Tonal; onClicked: root.runMono(["status"], "Mono status") }
                            TextButton { Layout.fillWidth: true; text: qsTr("Run diagnostics"); type: TextButton.Text; onClicked: root.runMono(["doctor"], "Mono diagnostics") }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            TextButton { Layout.fillWidth: true; text: qsTr("Check configuration"); type: TextButton.Text; onClicked: root.runMono(["check"], "Check configuration") }
                            TextButton { Layout.fillWidth: true; text: qsTr("Roll back Home Manager"); type: TextButton.Text; onClicked: root.runMono(["jump", "--pick"], "Choose Home Manager generation") }
                        }
                    }

                    SectionContainer {
                        Layout.fillWidth: true
                        alignTop: true
                        radius: Appearance.rounding.large
                        contentSpacing: Appearance.spacing.md
                        RowLayout {
                            Layout.fillWidth: true
                            MaterialIcon { text: "tune"; color: Colours.palette.m3secondary }
                            StyledText { Layout.fillWidth: true; text: qsTr("Configuration"); font.pointSize: Appearance.font.size.titleMedium; font.weight: 600 }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            TextButton { Layout.fillWidth: true; text: qsTr("Edit flake"); type: TextButton.Tonal; onClicked: root.runMono(["edit"], "Edit flake") }
                            TextButton { Layout.fillWidth: true; text: qsTr("Choose style"); type: TextButton.Text; onClicked: root.runMono(["style"], "Choose Monolix style") }
                        }
                    }
                }

                SectionContainer {
                    Layout.fillWidth: true
                    alignTop: true
                    radius: Appearance.rounding.large
                    contentSpacing: Appearance.spacing.md
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            StyledText { text: qsTr("Monolix service"); font.pointSize: Appearance.font.size.titleMedium; font.weight: 600 }
                            StyledText { text: root.monoOutput; color: Colours.palette.m3onSurfaceVariant; elide: Text.ElideRight; maximumLineCount: 2 }
                        }
                        TextButton { text: qsTr("Refresh status"); type: TextButton.Text; enabled: !root.monoBusy; onClicked: { root.monoBusy = true; monoProcess.command = ["mono", "status"]; monoProcess.running = true; } }
                        TextButton { text: qsTr("Restart shell"); type: TextButton.Tonal; onClicked: root.runMono(["shell", "restart"], "Restart Monolix") }
                        TextButton { text: qsTr("View logs"); type: TextButton.Text; onClicked: root.runMono(["shell", "logs"], "Monolix logs") }
                    }
                }
            }

            // Game library
            ColumnLayout {
                visible: root.activePage === "games"
                Layout.fillWidth: true
                spacing: Appearance.spacing.lg
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    TextButton { text: qsTr("Games folder"); type: TextButton.Tonal; onClicked: root.openFolder(`${Paths.home}/Games`) }
                    TextButton { text: qsTr("Steam library"); type: TextButton.Tonal; onClicked: root.openFolder(`${Paths.home}/.local/share/Steam/steamapps/common`) }
                }
                RowLayout {
                    Layout.fillWidth: true
                    TextButton { text: qsTr("Steam"); type: TextButton.Filled; onClicked: Quickshell.execDetached(["steam"]) }
                    TextButton { text: qsTr("Heroic"); type: TextButton.Tonal; onClicked: Quickshell.execDetached(["heroic"]) }
                    TextButton { text: qsTr("Lutris"); type: TextButton.Tonal; onClicked: Quickshell.execDetached(["lutris"]) }
                    StyledText { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; text: qsTr("%1 menu games · %2 custom").arg(root.installedGames.length).arg(GameLibrary.customGames.length); color: Colours.palette.m3onSurfaceVariant }
                }
                SectionContainer {
                    Layout.fillWidth: true
                    alignTop: true
                    contentSpacing: Appearance.spacing.md
                    StyledText { text: qsTr("Installed games"); font.pointSize: Appearance.font.size.titleMedium; font.weight: 600 }
                    StyledText { Layout.fillWidth: true; visible: root.installedGames.length === 0; text: qsTr("No games are registered in your application menu yet."); color: Colours.palette.m3onSurfaceVariant }
                    Repeater {
                        model: root.installedGames
                        delegate: GameRow { required property var modelData; Layout.fillWidth: true }
                    }
                }
                SectionContainer {
                    Layout.fillWidth: true
                    alignTop: true
                    contentSpacing: Appearance.spacing.md
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { Layout.fillWidth: true; text: qsTr("Your library"); font.pointSize: Appearance.font.size.titleMedium; font.weight: 600 }
                        StyledText { text: qsTr("Saved on this device"); color: Colours.palette.m3onSurfaceVariant }
                    }
                    Repeater {
                        model: GameLibrary.customGames
                        delegate: StyledRect {
                            id: customGameRow
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: gameRowContent.implicitHeight + Appearance.padding.sm * 2
                            radius: Appearance.rounding.medium
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                            RowLayout {
                                id: gameRowContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Appearance.padding.md
                                MaterialIcon { text: "sports_esports"; color: Colours.palette.m3primary }
                                StyledText { Layout.fillWidth: true; text: customGameRow.modelData.name; elide: Text.ElideRight }
                                TextButton { text: qsTr("Play"); type: TextButton.Filled; onClicked: GameLibrary.launch(customGameRow.modelData) }
                                TextButton { text: qsTr("Remove"); type: TextButton.Text; onClicked: GameLibrary.remove(customGameRow.modelData.id) }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        StyledTextField { id: gameNameField; Layout.fillWidth: true; placeholderText: qsTr("Game name") }
                        StyledTextField { id: gameCommandField; Layout.fillWidth: true; placeholderText: qsTr("Launch command") }
                        TextButton {
                            text: qsTr("Add game")
                            type: TextButton.Tonal
                            onClicked: {
                                GameLibrary.add(gameNameField.text, gameCommandField.text);
                                if (gameNameField.text.trim() && gameCommandField.text.trim()) {
                                    gameNameField.text = "";
                                    gameCommandField.text = "";
                                }
                            }
                        }
                    }
                    StyledText { Layout.fillWidth: true; visible: GameLibrary.statusText.length > 0; text: GameLibrary.statusText; color: Colours.palette.m3onSurfaceVariant }
                    StyledText { Layout.fillWidth: true; text: root.gameStatus; color: Colours.palette.m3onSurfaceVariant }
                }
            }

            // Curated online wallpapers; downloads are stored locally before applying.
            ColumnLayout {
                visible: root.activePage === "wallpapers"
                Layout.fillWidth: true
                spacing: Appearance.spacing.lg
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        StyledText { text: qsTr("Online wallpapers"); font.pointSize: Appearance.font.size.titleLarge; font.weight: 600 }
                        StyledText { text: qsTr("Browse Unsplash, Wallhaven, and 4K Wallpapers."); color: Colours.palette.m3onSurfaceVariant }
                    }
                    IconButton { type: IconButton.Text; icon: "folder_open"; onClicked: root.openFolder(Paths.wallsdir) }
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: Appearance.rounding.medium
                        color: Colours.palette.m3surfaceContainerHigh
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.padding.md
                            anchors.rightMargin: Appearance.padding.sm
                            MaterialIcon { text: "search"; color: Colours.palette.m3onSurfaceVariant }
                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Search wallpapers")
                                text: root.wallpaperSearch
                                onTextEdited: text => root.wallpaperSearch = text
                                onAccepted: root.browseWallpaperSource(root.wallpaperSource)
                            }
                            IconButton { type: IconButton.Text; icon: root.wallpaperSearching ? "hourglass_top" : "search"; disabled: root.wallpaperSearching; onClicked: root.browseWallpaperSource(root.wallpaperSource) }
                        }
                    }
                    IconButton { type: IconButton.Tonal; icon: "open_in_new"; onClicked: root.openWallpaperWebsite() }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.sm
                    TextButton { text: qsTr("Unsplash"); type: TextButton.Tonal; checked: root.wallpaperSource === "unsplash"; onClicked: root.browseWallpaperSource("unsplash") }
                    TextButton { text: qsTr("Wallhaven"); type: TextButton.Tonal; checked: root.wallpaperSource === "wallhaven"; onClicked: root.browseWallpaperSource("wallhaven") }
                    TextButton { text: qsTr("4K Wallpapers"); type: TextButton.Tonal; checked: root.wallpaperSource === "fourk"; onClicked: root.browseWallpaperSource("fourk") }
                    Item { Layout.fillWidth: true }
                    StyledText { text: root.wallpaperSource === "wallhaven" ? qsTr("Safe for work") : root.wallpaperSource === "fourk" ? qsTr("Website search") : qsTr("Featured picks"); color: Colours.palette.m3onSurfaceVariant; font.pointSize: Appearance.font.size.bodySmall }
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: root.wallpaperStatus.length > 0
                    text: root.wallpaperStatus
                    color: root.wallpaperStatus.toLowerCase().includes("failed") ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                }
                StyledText { Layout.fillWidth: true; text: root.wallpaperSource === "wallhaven" ? qsTr("Wallhaven results") : root.wallpaperSource === "fourk" ? qsTr("4K Wallpapers") : qsTr("Featured from Unsplash"); font.pointSize: Appearance.font.size.titleMedium; font.weight: 600 }
                GridLayout {
                    Layout.fillWidth: true
                    columns: width >= 900 ? 3 : 2
                    rowSpacing: Appearance.spacing.md
                    columnSpacing: Appearance.spacing.md
                    Repeater {
                        model: root.visibleWallpapers
                        delegate: OnlineWallpaperCard {
                            required property var modelData
                            Layout.fillWidth: true
                            wallpaper: modelData
                            compact: false
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: !root.wallpaperSearching && root.visibleWallpapers.length === 0
                    text: root.wallpaperSource === "unsplash"
                        ? qsTr("No featured wallpaper matches that search. Use the open button to search Unsplash online.")
                        : root.wallpaperSource === "wallhaven" ? qsTr("No results yet. Search Wallhaven or try another term.")
                        : qsTr("Use the open button to search 4K Wallpapers online.")
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                }
            }

        }
    }

    }

    component MetricCard: SectionContainer {
        id: metric
        required property string title
        required property string icon
        required property string value
        required property string detail
        required property real progress
        required property color accent
        Layout.fillWidth: true
        Layout.preferredHeight: 228
        alignTop: true
        contentSpacing: Appearance.spacing.sm

        RowLayout {
            Layout.fillWidth: true
            MaterialIcon { text: metric.icon; color: metric.accent; font.pointSize: Appearance.font.size.titleMedium }
            StyledText { Layout.fillWidth: true; text: metric.title; color: Colours.palette.m3onSurfaceVariant }
        }
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 118
            Layout.preferredHeight: 118

            Canvas {
                id: gauge
                anchors.fill: parent
                property real value: Math.max(0, Math.min(1, metric.progress))
                property color accent: metric.accent
                onValueChanged: requestPaint()
                onAccentChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const cx = width / 2;
                    const cy = height / 2;
                    const radius = Math.min(width, height) / 2 - 9;
                    ctx.lineWidth = 9;
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
                    ctx.strokeStyle = Colours.palette.m3surfaceContainerHighest;
                    ctx.stroke();
                    if (value > 0) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * value);
                        ctx.strokeStyle = accent;
                        ctx.stroke();
                    }
                }

                Behavior on value { Anim { duration: Appearance.anim.durations.normal } }
            }
            StyledText {
                anchors.centerIn: parent
                text: metric.value
                font.pointSize: Appearance.font.size.headlineSmall
                font.weight: 700
                color: metric.accent
            }
        }
        StyledText {
            Layout.fillWidth: true
            text: metric.detail
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.bodySmall
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    component ProcessListRow: StyledRect {
        id: processItem
        property var itemData: ({})
        property bool appMode: false
        readonly property string command: appMode ? String(itemData.command || qsTr("App")) : String(itemData.command || itemData.displayName || qsTr("Process"))
        readonly property real cpu: Number(itemData.cpu) || 0
        readonly property real memoryKb: Number(itemData.memoryKB) || 0
        Layout.fillWidth: true
        implicitHeight: 64
        radius: Appearance.rounding.medium
        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.sm
            anchors.rightMargin: Appearance.padding.xs
            spacing: Appearance.spacing.md

            StyledClippingRect {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: Appearance.rounding.medium
                color: Colours.palette.m3surfaceContainerHigh
                MaterialIcon {
                    anchors.centerIn: parent
                    text: SysMonitorService.getProcessIcon(processItem.command)
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.titleMedium
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.xs
                StyledText {
                    Layout.fillWidth: true
                    text: processItem.command
                    elide: Text.ElideRight
                    font.weight: 600
                }
                StyledText {
                    Layout.fillWidth: true
                    text: processItem.appMode
                        ? qsTr("%1 running processes").arg((processItem.itemData.processes || []).length)
                        : qsTr("PID %1").arg(processItem.itemData.pid)
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.bodySmall
                }
            }

            StyledText {
                Layout.preferredWidth: 112
                text: SysMonitorService.formatMemoryUsage(processItem.memoryKb)
                horizontalAlignment: Text.AlignRight
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.bodySmall
            }
            StyledText {
                Layout.preferredWidth: 78
                text: `${processItem.cpu.toFixed(1)}%`
                horizontalAlignment: Text.AlignRight
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.bodySmall
            }
            StyledText {
                Layout.preferredWidth: 54
                text: "—"
                horizontalAlignment: Text.AlignRight
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.bodySmall
            }
            IconButton {
                type: IconButton.Text
                icon: "stop_circle"
                onClicked: {
                    if (processItem.appMode)
                        (processItem.itemData.pids || []).forEach(pid => SysMonitorService.killProcess(Number(pid)));
                    else
                        SysMonitorService.killProcess(Number(processItem.itemData.pid));
                }
            }
        }
    }

    component GameRow: StyledRect {
        id: row
        required property var modelData
        readonly property var game: modelData
        property bool custom: false
        Layout.fillWidth: true
        implicitHeight: 58
        radius: Appearance.rounding.medium
        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
        StateLayer {
            disabled: row.custom
            function onClicked(): void {
                if (!row.custom)
                    Quickshell.execDetached(row.game.command);
            }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.md
            anchors.rightMargin: Appearance.padding.md
            MaterialIcon { text: "sports_esports"; color: Colours.palette.m3primary }
            StyledText { Layout.fillWidth: true; text: row.game.name; elide: Text.ElideRight }
            TextButton {
                text: qsTr("Play")
                type: TextButton.Tonal
                onClicked: row.custom ? GameLibrary.launch(row.game) : Quickshell.execDetached(row.game.command)
            }
            TextButton { visible: row.custom; text: qsTr("Remove"); type: TextButton.Text; onClicked: GameLibrary.remove(row.game.id) }
        }
    }

    component InfoRow: RowLayout {
        id: row
        required property string label
        required property string value
        Layout.fillWidth: true
        StyledText { Layout.fillWidth: true; text: row.label; color: Colours.palette.m3onSurfaceVariant }
        StyledText { Layout.maximumWidth: 180; text: row.value; color: Colours.palette.m3onSurface; elide: Text.ElideRight; horizontalAlignment: Text.AlignRight }
    }

    component OnlineWallpaperCard: StyledRect {
        id: card
        required property var wallpaper
        property bool compact: false
        implicitHeight: compact ? 112 : 220
        Layout.fillWidth: true
        radius: Appearance.rounding.large
        color: Colours.palette.m3surfaceContainerHigh
        clip: true
        Image {
            anchors.fill: parent
            source: card.wallpaper.url
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(width, height)
        }
        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: compact ? 42 : 58
            color: Qt.alpha(Colours.palette.m3surface, 0.9)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.padding.md
                anchors.rightMargin: Appearance.padding.sm
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.xs
                    StyledText { Layout.fillWidth: true; text: card.wallpaper.name; elide: Text.ElideRight; font.weight: 500 }
                    StyledText { visible: !card.compact; text: card.wallpaper.category; color: Colours.palette.m3onSurfaceVariant; font.pointSize: Appearance.font.size.bodySmall }
                }
                IconButton {
                    type: IconButton.Filled
                    icon: root.activeWallpaperPath.endsWith(`${card.wallpaper.id}.jpg`) && wallpaperDownloadProcess.running ? "downloading" : "download"
                    disabled: wallpaperDownloadProcess.running
                    onClicked: root.downloadWallpaper(card.wallpaper)
                }
            }
        }
    }
}
