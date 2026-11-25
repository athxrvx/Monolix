// Native system dashboard for performance, storage, hardware and logs.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services

FloatingWindow {
    id: root

    title: "System Monitor"
    visible: false
    implicitWidth: 1100
    implicitHeight: 720
    color: Theme.bg

    readonly property var pages: [
        { id: "performance", label: "Performance" },
        { id: "storage", label: "Storage" },
        { id: "hardware", label: "Hardware" },
        { id: "logs", label: "Logs" }
    ]
    property string page: "performance"
    readonly property color tableAlt: Theme.mix(Theme.bg, Theme.text, 0.06)

    function openWindow() { openPage("performance"); }
    function toggle() { visible ? visible = false : openWindow(); }
    function openPage(name) {
        if (pages.some(p => p.id === name)) page = name;
        visible = true;
        Qt.callLater(() => MonitorData.refreshPage(page));
    }
    function refreshPage() { MonitorData.refreshPage(page); }

    onVisibleChanged: MonitorData.setActive(visible)
    onPageChanged: if (visible) Qt.callLater(() => MonitorData.refreshPage(page))

    Timer {
        interval: root.page === "logs" ? 6000 : 15000
        repeat: true
        running: root.visible && root.page !== "performance"
        onTriggered: root.refreshPage()
    }

    component ActionButton: Rectangle {
        id: action
        property string label: ""
        property bool emphasized: false
        property bool disabled: false
        signal clicked()
        implicitWidth: labelText.implicitWidth + 18
        implicitHeight: 28
        color: action.emphasized ? Theme.surface2 : root.tableAlt
        border.width: 1
        border.color: action.emphasized ? Theme.accent : Theme.border
        opacity: action.disabled ? 0.4 : 1

        Text {
            id: labelText
            anchors.centerIn: parent
            text: action.label
            color: action.emphasized ? Theme.text : Theme.subtext
            font.family: Theme.font
            font.pixelSize: 11
        }
        MouseArea {
            anchors.fill: parent
            enabled: !action.disabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: action.clicked()
        }
    }

    component MetricRow: Rectangle {
        id: metricRow
        property string label: ""
        property string value: ""
        property string icon: ""
        property string metric: ""
        property color graphColor: Theme.accent
        Layout.fillWidth: true
        Layout.preferredHeight: 74
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 16
            RowLayout {
                Layout.preferredWidth: 170
                spacing: 10
                Text {
                    text: metricRow.icon
                    color: metricRow.graphColor
                    font.family: Theme.iconFont
                    font.pixelSize: 20
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        Layout.fillWidth: true
                        text: metricRow.label
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: metricRow.value
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
            }
            Canvas {
                id: graph
                Layout.fillWidth: true
                Layout.fillHeight: true
                antialiasing: true
                Connections {
                    target: MonitorData
                    function onRevisionChanged() { graph.requestPaint(); }
                }
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.fillStyle = Theme.bg;
                    ctx.fillRect(0, 0, width, height);
                    ctx.strokeStyle = Theme.border;
                    ctx.lineWidth = 1;
                    for (let i = 1; i < 4; i++) {
                        const gy = Math.round(height * i / 4) + 0.5;
                        ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke();
                    }
                    const points = MonitorData.historyFor(metricRow.metric);
                    if (points.length < 2 || width <= 0 || height <= 0) return;
                    const pad = 3, plotH = height - pad * 2;
                    const xAt = i => i * width / (points.length - 1);
                    const yAt = v => height - pad - Math.max(0, Math.min(1, v)) * plotH;
                    ctx.beginPath(); ctx.moveTo(xAt(0), yAt(points[0]));
                    for (let i = 1; i < points.length; i++) ctx.lineTo(xAt(i), yAt(points[i]));
                    ctx.lineTo(width, height - pad); ctx.lineTo(0, height - pad); ctx.closePath();
                    ctx.fillStyle = Qt.rgba(metricRow.graphColor.r, metricRow.graphColor.g, metricRow.graphColor.b, 0.13);
                    ctx.fill();
                    ctx.beginPath(); ctx.moveTo(xAt(0), yAt(points[0]));
                    for (let i = 1; i < points.length; i++) ctx.lineTo(xAt(i), yAt(points[i]));
                    ctx.strokeStyle = metricRow.graphColor; ctx.lineWidth = 2; ctx.stroke();
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 2
                Text {
                    text: "System task manager"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 21
                    font.bold: true
                }
                Text {
                    text: root.page === "logs" ? "Recent boot log · latest 150 lines"
                        : root.page === "performance" ? "Live system activity · 60 second history"
                        : "System resources and hardware details"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                }
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: root.page === "performance"
                text: root.visible ? "LIVE" : "PAUSED"
                color: root.visible ? Theme.accent : Theme.muted
                font.family: Theme.font
                font.pixelSize: 11
                font.letterSpacing: 1
            }
            ActionButton {
                label: "Refresh"
                emphasized: true
                onClicked: root.refreshPage()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: root.pages
                Rectangle {
                    id: tab
                    required property var modelData
                    implicitWidth: tabLabel.implicitWidth + 26
                    implicitHeight: 36
                    color: root.page === modelData.id ? Theme.surface2 : "transparent"
                    border.width: root.page === modelData.id ? 1 : 0
                    border.color: Theme.accent
                    Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: tab.modelData.label
                        color: root.page === tab.modelData.id ? Theme.text : Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openPage(tab.modelData.id)
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: MonitorData.detailError !== "" || (root.page === "hardware" && SystemInfo.error !== "")
            implicitHeight: visible ? 34 : 0
            color: Theme.surface
            border.width: 1
            border.color: Theme.warning
            Text {
                anchors.fill: parent
                anchors.margins: 8
                text: MonitorData.detailError !== "" ? MonitorData.detailError : SystemInfo.error
                color: Theme.warning
                font.family: Theme.font
                font.pixelSize: 11
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: Math.max(0, root.pages.findIndex(p => p.id === root.page))

            // Performance
            ColumnLayout {
                spacing: 8
                MetricRow { label: "CPU"; value: Math.round(MonitorData.cpu * 100) + "%"; icon: Icons.cpu; metric: "cpu"; graphColor: Theme.accent }
                MetricRow { label: "Memory"; value: Math.round(MonitorData.memory * 100) + "%"; icon: Icons.memory; metric: "memory"; graphColor: Theme.info }
                MetricRow { label: "Disk"; value: MonitorData.formatRate(MonitorData.diskRate); icon: Icons.g(0xF02CA); metric: "disk"; graphColor: Theme.warning }
                MetricRow { label: "Network"; value: MonitorData.networkConnected ? MonitorData.formatRate(MonitorData.networkRate) : "offline"; icon: MonitorData.networkConnected ? Icons.wifi : Icons.wifiOff; metric: "network"; graphColor: Theme.teal }
                MetricRow { label: "GPU"; value: !GpuStatus.available ? "unavailable" : (GpuStatus.running ? "active" : "idle") + " · " + GpuStatus.utilization + "%"; icon: Icons.cpu; metric: "gpu"; graphColor: Theme.rose }
            }

            // Filesystem usage
            ColumnLayout {
                spacing: 0
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 34; color: Theme.surface
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                        Text { Layout.fillWidth: true; text: "FILESYSTEM / MOUNT"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                        Text { Layout.preferredWidth: 84; text: "TYPE"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                        Text { Layout.preferredWidth: 66; text: "USED"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
                        Text { Layout.preferredWidth: 66; text: "FREE"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
                        Text { Layout.preferredWidth: 58; text: "USE"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
                        Item { Layout.preferredWidth: 100 }
                    }
                }
                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; model: MonitorData.filesystems; boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle {
                        id: diskRow
                        required property var modelData
                        width: ListView.view.width; height: 42
                        color: index % 2 === 0 ? Theme.bg : root.tableAlt
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { Layout.fillWidth: true; text: diskRow.modelData.mount; color: Theme.text; font.family: Theme.font; font.pixelSize: 11; elide: Text.ElideMiddle }
                                Text { Layout.fillWidth: true; text: diskRow.modelData.device; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9; elide: Text.ElideMiddle }
                            }
                            Text { Layout.preferredWidth: 84; text: diskRow.modelData.type; color: Theme.subtext; font.family: Theme.font; font.pixelSize: 10; elide: Text.ElideRight }
                            Text { Layout.preferredWidth: 66; text: diskRow.modelData.used; color: Theme.subtext; font.family: Theme.font; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
                            Text { Layout.preferredWidth: 66; text: diskRow.modelData.available; color: Theme.subtext; font.family: Theme.font; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
                            Text { Layout.preferredWidth: 58; text: diskRow.modelData.percent + "%"; color: diskRow.modelData.percent > 85 ? Theme.warning : Theme.text; font.family: Theme.font; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
                            Rectangle {
                                Layout.preferredWidth: 100; Layout.preferredHeight: 5
                                color: Theme.surface2
                                Rectangle { width: parent.width * Math.max(0, Math.min(100, diskRow.modelData.percent)) / 100; height: parent.height; color: diskRow.modelData.percent > 85 ? Theme.warning : Theme.accent }
                            }
                        }
                    }
                }
            }

            // Hardware details
            Flickable {
                clip: true
                contentWidth: width
                contentHeight: hardwareGrid.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                GridLayout {
                    id: hardwareGrid
                    width: parent.width
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 12
                Repeater {
                    model: [
                        { label: "Operating system", value: SystemInfo.os },
                        { label: "Kernel", value: SystemInfo.kernel },
                        { label: "Hostname", value: SystemInfo.host },
                        { label: "Uptime", value: SystemInfo.uptime },
                        { label: "Compositor", value: SystemInfo.compositor },
                        { label: "Display", value: SystemInfo.resolution },
                        { label: "Processor", value: SystemInfo.cpu },
                        { label: "Architecture / threads", value: (SystemInfo.platformInfo.architecture ?? "—") + " · " + (SystemInfo.platformInfo.logical_threads ?? "—") },
                        { label: "CPU load", value: Math.round(MonitorData.cpu * 100) + "% · " + SystemStats.temp + "°C" },
                        { label: "Memory", value: SystemStats.formatKiB(SystemStats.memUsed) + " / " + SystemStats.formatKiB(SystemStats.memTotal) },
                        { label: "System vendor", value: SystemInfo.platformInfo.sys_vendor ?? "—" },
                        { label: "System model", value: SystemInfo.platformInfo.product_name ?? "—" },
                        { label: "Motherboard", value: [SystemInfo.platformInfo.board_vendor, SystemInfo.platformInfo.board_name].filter(Boolean).join(" · ") || "—" },
                        { label: "BIOS", value: [SystemInfo.platformInfo.bios_vendor, SystemInfo.platformInfo.bios_version].filter(Boolean).join(" · ") || "—" }
                    ].concat(SystemInfo.disks.map((disk, index) => ({
                        label: "Drive " + (index + 1) + " · " + disk.type,
                        value: [disk.name, disk.model, disk.size].filter(Boolean).join(" · ")
                    }))).concat(SystemInfo.gpus.map((gpu, index) => ({
                        label: gpu.vendor + " GPU " + (index + 1),
                        value: gpu.vendor === "NVIDIA"
                            ? gpu.name + " · " + gpu.memoryUsed + "/" + gpu.memoryTotal + " MiB · "
                                + gpu.utilization + "% · " + gpu.temperature + "°C · driver " + gpu.driver
                            : gpu.name + (gpu.kind ? " · " + gpu.kind : "")
                    })))
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 84
                        color: Theme.surface
                        border.width: 1
                        border.color: Theme.border
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 8
                            Text { text: modelData.label.toUpperCase(); color: Theme.muted; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1 }
                            Text { Layout.fillWidth: true; text: modelData.value || "—"; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; elide: Text.ElideRight }
                        }
                    }
                }
                }
            }

            // Recent logs
            Flickable {
                clip: true
                contentWidth: width
                contentHeight: logsText.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                TextEdit {
                    id: logsText
                    width: parent.width
                    text: MonitorData.logs || "Loading journal…"
                    color: Theme.text
                    selectedTextColor: Theme.bg
                    selectionColor: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 11
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                }
            }
        }
    }
}
