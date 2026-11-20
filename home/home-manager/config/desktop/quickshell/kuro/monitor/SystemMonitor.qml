// Standalone live system monitor window, opened from Launcher > Control.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services

FloatingWindow {
    id: root

    title: "System Monitor"
    visible: false
    implicitWidth: 820
    implicitHeight: 560
    color: Theme.bg

    function openWindow() { visible = true; }
    function toggle() { visible = !visible; }

    onVisibleChanged: MonitorData.setActive(visible)

    component MetricRow: Rectangle {
        id: row
        property string label: ""
        property string value: ""
        property string icon: ""
        property string metric: ""
        property color graphColor: Theme.accent

        Layout.fillWidth: true
        Layout.preferredHeight: 76
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 18

            RowLayout {
                Layout.preferredWidth: 160
                spacing: 10

                Text {
                    text: row.icon
                    color: row.graphColor
                    font.family: Theme.iconFont
                    font.pixelSize: 20
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        Layout.fillWidth: true
                        text: row.label
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: row.value
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
                        ctx.beginPath();
                        ctx.moveTo(0, gy);
                        ctx.lineTo(width, gy);
                        ctx.stroke();
                    }

                    const points = MonitorData.historyFor(row.metric);
                    if (points.length < 2 || width <= 0 || height <= 0) return;
                    const pad = 3;
                    const plotH = height - pad * 2;
                    const xAt = i => i * width / (points.length - 1);
                    const yAt = v => height - pad - Math.max(0, Math.min(1, v)) * plotH;
                    ctx.beginPath();
                    ctx.moveTo(xAt(0), yAt(points[0]));
                    for (let i = 1; i < points.length; i++) ctx.lineTo(xAt(i), yAt(points[i]));
                    ctx.lineTo(width, height - pad);
                    ctx.lineTo(0, height - pad);
                    ctx.closePath();
                    ctx.fillStyle = Qt.rgba(row.graphColor.r, row.graphColor.g, row.graphColor.b, 0.13);
                    ctx.fill();
                    ctx.beginPath();
                    ctx.moveTo(xAt(0), yAt(points[0]));
                    for (let i = 1; i < points.length; i++) ctx.lineTo(xAt(i), yAt(points[i]));
                    ctx.strokeStyle = row.graphColor;
                    ctx.lineWidth = 2;
                    ctx.lineJoin = "round";
                    ctx.lineCap = "round";
                    ctx.stroke();
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "System monitor"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 20
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.visible ? "LIVE  ·  1 SEC" : "PAUSED"
                color: root.visible ? Theme.accent : Theme.muted
                font.family: Theme.font
                font.pixelSize: 11
                font.letterSpacing: 1
            }
        }

        Text {
            text: "Recent activity · up to 60 seconds"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 12
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            MetricRow {
                label: "CPU"
                value: Math.round(MonitorData.cpu * 100) + "%"
                icon: Icons.cpu
                metric: "cpu"
                graphColor: Theme.accent
            }
            MetricRow {
                label: "Memory"
                value: Math.round(MonitorData.memory * 100) + "%"
                icon: Icons.memory
                metric: "memory"
                graphColor: Theme.info
            }
            MetricRow {
                label: "Disk"
                value: MonitorData.formatRate(MonitorData.diskRate)
                icon: Icons.g(0xF02CA)
                metric: "disk"
                graphColor: Theme.warning
            }
            MetricRow {
                label: "Wi-Fi"
                value: MonitorData.wifiConnected ? MonitorData.formatRate(MonitorData.wifiRate) : "offline"
                icon: MonitorData.wifiConnected ? Icons.wifi : Icons.wifiOff
                metric: "wifi"
                graphColor: Theme.teal
            }
            MetricRow {
                label: "GPU"
                value: !GpuStatus.available ? "unavailable"
                    : (GpuStatus.running ? "active" : "idle") + "  ·  " + GpuStatus.utilization + "%"
                icon: Icons.cpu
                metric: "gpu"
                graphColor: Theme.rose
            }
        }

        Text {
            Layout.fillWidth: true
            text: "CPU and memory use system counters · Disk and Wi-Fi show read/write and receive/transmit rates · GPU shows utilization"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
    }
}
