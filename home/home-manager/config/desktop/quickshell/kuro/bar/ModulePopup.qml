// Compact Omarchy-style click popup for a bar module, anchored under the item.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config
import qs.services
import qs.components

PopupWindow {
    id: popup

    required property var barWindow
    required property Item target
    readonly property bool requestedOpen: BarPopup.open && BarPopup.kind !== ""

    readonly property string title: ({
        network: "Network", volume: "Sound", mic: "Microphone",
        brightness: "Brightness", battery: "Battery",
        memory: "Memory", profile: "Power profile", bluetooth: "Bluetooth",
        clipboard: "Clipboard", mouse: "Mouse", window: "Window", tray: "System tray", ai: "Kuro AI"
    })[BarPopup.kind] ?? BarPopup.kind

    function place() {
        const p = target.mapToItem(null, target.width / 2, target.height);
        const x = Math.round(p.x - implicitWidth / 2);
        const edge = Theme.popupGap;
        const maxX = Math.max(edge, barWindow.width - implicitWidth - edge);
        anchor.rect.x = Math.max(edge, Math.min(x, maxX));
        anchor.rect.y = Math.round(p.y + Theme.popupGap);
    }

    function componentFor(kind) {
        return ({
            network: networkC, volume: volumeC, mic: micC,
            brightness: brightnessC, battery: batteryC,
            memory: memoryC, profile: profileC, bluetooth: bluetoothC,
            clipboard: clipboardC, mouse: mouseC, window: windowC, tray: trayC
        })[kind] ?? null;
    }

    function refresh() {
        switch (BarPopup.kind) {
            case "network":    Network.refresh(true); break;
            case "volume":
            case "mic":        Audio.refresh(); break;
            case "brightness": Brightness.refresh(); break;
            case "battery":    Battery.refresh(); PowerProfile.refresh(); GpuStatus.refresh(true); Brightness.refresh(); break;
            case "memory":     SystemStats.refresh(); break;
            case "profile":    PowerProfile.refresh(); GpuStatus.refresh(true); break;
            case "bluetooth":  Bluetooth.refresh(); break;
            case "clipboard":  Clipboard.refresh(); break;
            case "mouse":      MouseBattery.refresh(); break;
        }
    }

    anchor.window: barWindow
    grabFocus: true
    visible: popup.requestedOpen || popupSurface.opacity > 0
    implicitWidth: Math.min(320, Math.max(1, barWindow.width - Theme.popupGap * 2))
    implicitHeight: Math.min(480, body.implicitHeight + 24)
    color: "transparent"

    onVisibleChanged: {
        if (!visible && popup.requestedOpen) {
            BarPopup.close();
        } else if (visible && popup.requestedOpen) {
            place();
            refresh();
        }
    }

    Connections {
        target: BarPopup
        function onKindChanged() {
            if (popup.requestedOpen) { popup.place(); popup.refresh(); }
        }
        function onTargetChanged() {
            if (popup.requestedOpen) popup.place();
        }
    }

    Rectangle {
        id: popupSurface
        anchors.fill: parent
        radius: 0
        color: Theme.bg
        border.color: Theme.border
        clip: true
        opacity: popup.requestedOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: popup.requestedOpen ? 0 : -8
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 12
            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: body.implicitHeight

            ColumnLayout {
                id: body
                width: parent.width
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: popup.title.toUpperCase()
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.letterSpacing: 1.5
                    }

                    TextButton { radius: 0;
                        text: Icons.close
                        onClicked: BarPopup.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                Loader {
                    Layout.fillWidth: true
                    sourceComponent: popup.componentFor(BarPopup.kind)
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 4
                visible: flick.contentHeight > flick.height && BarPopup.kind !== "network"
                color: "transparent"

                Rectangle {
                    width: 3
                    x: 1
                    height: Math.max(24, flick.height * flick.visibleArea.heightRatio)
                    y: flick.visibleArea.yPosition * flick.height
                    radius: 0
                    color: Theme.border
                }
            }
        }
    }

    Component {
        id: networkC
        ColumnLayout {
            id: networkBody
            property string selectedSsid: ""
            spacing: 10

            Connections {
                target: Network
                function onReauthSsidChanged() {
                    if (Network.reauthSsid) networkBody.selectedSsid = Network.reauthSsid;
                }
            }

            // Connection summary and radio controls
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: summary.implicitHeight + 20
                color: Theme.surface
                border.color: Theme.border
                radius: Theme.radiusSmall

                RowLayout {
                    id: summary
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Text {
                        text: Network.ethConnected ? Icons.ethernet : (Network.enabled ? Icons.wifi : Icons.wifiOff)
                        color: Network.online ? Theme.accent : Theme.muted
                        font.family: Theme.iconFont
                        font.pixelSize: 22
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: Network.ethConnected ? "Ethernet connected" : Network.ssid || "Wi-Fi disconnected"
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: Network.ethConnected ? [Network.ethIp, Network.ethSpeed].filter(Boolean).join(" · ")
                                : !Network.enabled ? "Wireless radio is off"
                                : Network.ssid ? (Network.wifiIp || "Connected") : "Choose a network below"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        text: Network.busy ? "…" : Network.online ? Icons.check : ""
                        color: Theme.accent
                        font.family: Theme.iconFont
                        font.pixelSize: 16
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextButton {
                    Layout.fillWidth: true
                    text: Network.busy ? "Updating…" : Network.enabled ? "Turn Wi-Fi off" : "Turn Wi-Fi on"
                    enabled: !Network.busy
                    primary: !Network.enabled
                    onClicked: Network.toggle()
                }
                TextButton {
                    text: Network.scanning ? "Scanning…" : Icons.refresh + "  Rescan"
                    enabled: Network.enabled && !Network.scanning && !Network.busy
                    onClicked: Network.scan(true)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: errorLabel.implicitHeight + 14
                visible: Network.error !== ""
                color: Theme.surface
                border.color: Theme.danger
                radius: Theme.radiusSmall
                Text {
                    id: errorLabel
                    anchors.fill: parent
                    anchors.margins: 8
                    text: Network.error
                    color: Theme.danger
                    font.family: Theme.font
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: Network.enabled
                Text {
                    Layout.fillWidth: true
                    text: "NETWORKS"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 10
                    font.letterSpacing: 1.2
                }
                Text {
                    text: Network.scanning ? "Searching nearby…" : Network.networks.length + " found"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 10
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: !Network.enabled || (!Network.scanning && Network.networks.length === 0)
                    || (Network.scanning && Network.networks.length === 0)
                implicitHeight: emptyState.implicitHeight + 28
                color: "transparent"
                border.color: Theme.border
                radius: Theme.radiusSmall
                Text {
                    id: emptyState
                    anchors.fill: parent
                    anchors.margins: 12
                    text: !Network.enabled ? "Turn Wi-Fi on to find nearby networks."
                        : Network.scanning ? "Scanning for nearby networks…"
                        : "No networks found. Rescan to try again."
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                }
            }

            Repeater {
                model: Network.networks
                delegate: Rectangle {
                    id: networkCard
                    required property var modelData
                    readonly property bool selected: networkBody.selectedSsid === modelData.ssid
                    readonly property bool needsPassword: Network.reauthSsid === modelData.ssid
                        || (modelData.secure && !modelData.known && !modelData.active)
                    Layout.fillWidth: true
                    implicitHeight: cardContent.implicitHeight + 18
                    color: modelData.active ? Theme.surface : selected ? Theme.surface2 : "transparent"
                    border.color: modelData.active ? Theme.accent : selected ? Theme.border : "transparent"
                    radius: Theme.radiusSmall

                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 8

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: networkHead.implicitHeight
                            RowLayout {
                                id: networkHead
                                anchors.fill: parent
                                spacing: 9
                                Text {
                                    text: Icons.wifiStrength[Math.min(4, Math.floor(networkCard.modelData.signal / 20))]
                                    color: networkCard.modelData.active ? Theme.accent : Theme.subtext
                                    font.family: Theme.iconFont
                                    font.pixelSize: 18
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        Layout.fillWidth: true
                                        text: networkCard.modelData.ssid
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 1
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: networkCard.modelData.known ? "Saved · " + networkCard.modelData.security
                                            : networkCard.modelData.security
                                        color: Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }
                                Text {
                                    text: networkCard.modelData.active ? "CONNECTED"
                                        : Network.connecting === networkCard.modelData.ssid ? "CONNECTING…"
                                        : networkCard.modelData.signal + "%"
                                    color: networkCard.modelData.active ? Theme.accent : Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 9
                                    font.letterSpacing: 0.5
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: networkBody.selectedSsid = networkCard.selected ? "" : networkCard.modelData.ssid
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: networkCard.selected
                            spacing: 8

                            InputField {
                                id: passwordField
                                visible: networkCard.needsPassword
                                password: true
                                placeholder: "Wi-Fi password"
                                onVisibleChanged: if (visible && networkCard.selected)
                                    Qt.callLater(() => passwordField.forceFocus())
                                onAccepted: {
                                    if (text.length > 0) {
                                        Network.connect(networkCard.modelData, text);
                                        text = "";
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: Network.reauthSsid === networkCard.modelData.ssid ? "Password changed? Enter the new one"
                                        : networkCard.needsPassword ? "Password required for this network"
                                        : networkCard.modelData.known ? "Using saved credentials"
                                        : networkCard.modelData.active ? "Currently connected"
                                        : "Open network"
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                                TextButton {
                                    visible: networkCard.modelData.active
                                    text: "Disconnect"
                                    enabled: Network.connecting === "" && !Network.busy
                                    onClicked: Network.disconnect()
                                }
                                TextButton {
                                    visible: !networkCard.modelData.active
                                    primary: true
                                    text: Network.connecting === networkCard.modelData.ssid ? "Connecting…" : "Connect"
                                    enabled: Network.connecting === "" && !Network.busy
                                        && (!networkCard.needsPassword || passwordField.text.length > 0)
                                    onClicked: {
                                        Network.connect(networkCard.modelData, passwordField.text);
                                        passwordField.text = "";
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: volumeC
        ColumnLayout {
            id: volumePopup
            property bool showStreams: false
            spacing: 10

            ValueSlider { trackRadius: 0; handleRadius: 0;
                from: 0
                to: 100
                value: Math.round(Audio.volume * 100)
                label: "Volume"
                suffix: "%"
                onMoved: v => Audio.setVolume(v / 100)
            }

            RowLayout {
                Layout.fillWidth: true
                TextButton { radius: 0;
                    text: Audio.muted ? "Unmute" : "Mute"
                    primary: Audio.muted
                    onClicked: Audio.toggleMute()
                }
                Item { Layout.fillWidth: true }
            }

            Repeater {
                model: Audio.sinks
                ListRow { radius: 0;
                    icon: Icons.speaker
                    title: modelData.name
                    sub: modelData.isDefault ? "Default output" : "Output"
                    active: modelData.isDefault
                    onClicked: Audio.setDefault(modelData, true)
                }
            }

            TextButton {
                Layout.fillWidth: true
                radius: 0
                text: volumePopup.showStreams ? "Hide per-app volume" : "Per-app volume"
                onClicked: {
                    volumePopup.showStreams = !volumePopup.showStreams;
                    if (volumePopup.showStreams) Audio.refresh();
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: volumePopup.showStreams
                spacing: 4

                Text {
                    visible: Audio.streams.length === 0
                    text: "No apps are playing audio."
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }

                Repeater {
                    model: Audio.streams
                    ListRow {
                        required property var modelData
                        radius: 0
                        icon: Icons.volume
                        title: modelData.name
                        sub: modelData.app
                        interactive: false
                        RowLayout {
                            Layout.fillWidth: true
                            ValueSlider {
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: Math.round(modelData.volume * 100)
                                label: ""
                                suffix: "%"
                                onMoved: v => Audio.setStreamVolume(modelData, v / 100)
                            }
                            TextButton {
                                radius: 0
                                text: modelData.muted ? "Unmute" : "Mute"
                                onClicked: Audio.toggleStreamMute(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: micC
        ColumnLayout {
            spacing: 10

            ValueSlider { trackRadius: 0; handleRadius: 0;
                from: 0
                to: 100
                value: Math.round(Audio.micVolume * 100)
                label: "Microphone"
                suffix: "%"
                onMoved: v => Audio.setMicVolume(v / 100)
            }

            TextButton { radius: 0;
                text: Audio.micMuted ? "Unmute microphone" : "Mute microphone"
                primary: Audio.micMuted
                onClicked: Audio.toggleMicMute()
            }
        }
    }

    Component {
        id: brightnessC
        ColumnLayout {
            spacing: 10

            ValueSlider { trackRadius: 0; handleRadius: 0;
                from: 1
                to: 100
                value: Math.round(Brightness.value * 100)
                label: "Brightness"
                suffix: "%"
                onMoved: v => Brightness.setValue(v / 100)
            }
        }
    }

    Component {
        id: batteryC
        ColumnLayout {
            spacing: 8

            ValueSlider { trackRadius: 0; handleRadius: 0;
                from: 1
                to: 100
                value: Math.round(Brightness.value * 100)
                label: "Brightness"
                suffix: "%"
                visible: Brightness.available
                onMoved: v => Brightness.setValue(v / 100)
            }

            ListRow { radius: 0;
                icon: Icons.cpu
                title: GpuStatus.running ? "GPU running"
                    : GpuStatus.available ? "GPU idle" : "GPU status unavailable"
                sub: GpuStatus.summary
                trailing: GpuStatus.available ? GpuStatus.utilization + "%"
                    : Capture.recording ? "recording" : ""
                active: GpuStatus.running
                interactive: false
            }

            Text {
                visible: !PowerProfile.available
                text: "Power profile service unavailable"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }

            ListRow { radius: 0;
                icon: Battery.charging ? Icons.charging : Icons.battery
                title: Battery.percent + "%"
                sub: Battery.status || "Battery"
                trailing: Battery.timeLeft
                active: true
                interactive: false
            }

            Text {
                Layout.fillWidth: true
                text: "Power draw: " + Battery.watts.toFixed(1) + " W"
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }

            Repeater {
                model: PowerProfile.profiles
                ListRow { radius: 0;
                    icon: modelData === "performance" ? Icons.speed : modelData === "power-saver" ? Icons.leaf : Icons.balance
                    title: PowerProfile.pretty(modelData)
                    active: modelData === PowerProfile.current
                    busy: PowerProfile.applying
                    onClicked: PowerProfile.set(modelData)
                }
            }

            Text {
                visible: PowerProfile.error !== ""
                text: PowerProfile.error
                color: Theme.danger
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
        }
    }

    Component {
        id: memoryC
        ColumnLayout {
            spacing: 8

            ListRow { radius: 0;
                icon: Icons.cpu
                title: "CPU " + Math.round(SystemStats.cpu * 100) + "%"
                sub: "Current processor usage"
                active: true
                interactive: false
            }

            ListRow { radius: 0;
                icon: Icons.memory
                title: Math.round(SystemStats.mem * 100) + "% used"
                sub: SystemStats.formatKiB(SystemStats.memUsed) + " / " + SystemStats.formatKiB(SystemStats.memTotal)
                active: true
                interactive: false
            }

            Text {
                Layout.fillWidth: true
                text: "Temperature: " + (SystemStats.temp > 0 ? SystemStats.temp + " °C" : "n/a")
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
        }
    }

    Component {
        id: profileC
        ColumnLayout {
            spacing: 8

            ListRow { radius: 0;
                icon: Icons.cpu
                title: GpuStatus.running ? "GPU running"
                    : GpuStatus.available ? "GPU idle" : "GPU status unavailable"
                sub: GpuStatus.summary
                trailing: GpuStatus.available ? GpuStatus.utilization + "%"
                    : Capture.recording ? "recording" : ""
                active: GpuStatus.running
                interactive: false
            }

            Text {
                visible: !PowerProfile.available
                text: "Power profile service unavailable"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }

            Repeater {
                model: PowerProfile.profiles
                ListRow { radius: 0;
                    icon: modelData === "performance" ? Icons.speed : modelData === "power-saver" ? Icons.leaf : Icons.balance
                    title: PowerProfile.pretty(modelData)
                    active: modelData === PowerProfile.current
                    busy: PowerProfile.applying
                    onClicked: PowerProfile.set(modelData)
                }
            }

            Text {
                visible: PowerProfile.error !== ""
                text: PowerProfile.error
                color: Theme.danger
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
        }
    }

    Component {
        id: bluetoothC
        ColumnLayout {
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: btSummary.implicitHeight + 20
                color: Theme.surface
                border.color: Theme.border

                RowLayout {
                    id: btSummary
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    Text {
                        text: !Bluetooth.available ? Icons.bluetoothOff
                            : Bluetooth.powered ? (Bluetooth.device ? Icons.bluetoothOn : Icons.bluetooth)
                            : Icons.bluetoothOff
                        color: Bluetooth.powered ? Theme.accent : Theme.muted
                        font.family: Theme.iconFont
                        font.pixelSize: 22
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: !Bluetooth.available ? "Bluetooth unavailable"
                                : Bluetooth.device || (Bluetooth.powered ? "Bluetooth on" : "Bluetooth off")
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: !Bluetooth.available ? "No adapter detected"
                                : Bluetooth.powered ? (Bluetooth.devices.filter(d => d.paired).length + " paired devices")
                                : "Turn Bluetooth on to find devices"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                    Text { visible: Bluetooth.busy; text: "…"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 16 }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextButton {
                    Layout.fillWidth: true
                    text: Bluetooth.busy ? "Updating…" : Bluetooth.powered ? "Turn Bluetooth off" : "Turn Bluetooth on"
                    enabled: Bluetooth.available && !Bluetooth.busy
                    primary: !Bluetooth.powered
                    sharp: true
                    onClicked: Bluetooth.toggle()
                }
                TextButton {
                    text: Bluetooth.scanning ? "Scanning…" : Icons.refresh + "  Scan"
                    enabled: Bluetooth.powered && !Bluetooth.scanning && !Bluetooth.busy
                    sharp: true
                    onClicked: Bluetooth.scan()
                }
            }

            Text {
                Layout.fillWidth: true
                visible: Bluetooth.error !== ""
                text: Bluetooth.error
                color: Theme.danger
                font.family: Theme.font
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                visible: Bluetooth.powered
                Text {
                    Layout.fillWidth: true
                    text: "DEVICES"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 10
                    font.letterSpacing: 1.2
                }
                Text {
                    text: Bluetooth.scanning ? "Searching nearby…" : Bluetooth.devices.length + " found"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 10
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !Bluetooth.powered || Bluetooth.devices.length === 0
                text: !Bluetooth.available ? "Bluetooth adapter unavailable."
                    : !Bluetooth.powered ? "Turn Bluetooth on to find nearby devices."
                    : Bluetooth.scanning ? "Scanning for nearby devices…"
                    : "No devices yet. Scan to find nearby devices."
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                Layout.topMargin: 8
                Layout.bottomMargin: 8
            }

            Repeater {
                model: Bluetooth.devices
                delegate: Rectangle {
                    id: btCard
                    required property var modelData
                    visible: Bluetooth.powered
                    Layout.fillWidth: true
                    implicitHeight: btRow.implicitHeight + 18
                    color: modelData.connected ? Theme.surface : "transparent"
                    border.color: modelData.connected ? Theme.accent : Theme.border

                    RowLayout {
                        id: btRow
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 9
                        Text {
                            text: modelData.connected ? Icons.bluetoothOn : Icons.bluetooth
                            color: modelData.connected ? Theme.accent : Theme.subtext
                            font.family: Theme.iconFont
                            font.pixelSize: 18
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.connected ? "Connected"
                                    : modelData.paired ? "Paired · " + modelData.mac : modelData.mac
                                color: modelData.connected ? Theme.accent : Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                        TextButton {
                            text: Bluetooth.pending === modelData.mac ? "…"
                                : modelData.connected ? "Disconnect"
                                : modelData.paired ? "Connect" : "Pair"
                            enabled: Bluetooth.pending === "" && Bluetooth.powered
                            primary: !modelData.connected
                            sharp: true
                            onClicked: Bluetooth.toggleDevice(modelData)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: clipboardC
        ColumnLayout {
            spacing: 8

            Repeater {
                model: Clipboard.items.slice(0, 8)
                ListRow { radius: 0;
                    icon: Icons.clipboard
                    title: modelData.image ? (modelData.meta || "Image") : (modelData.text || "Text")
                    sub: modelData.image ? "" : (modelData.text || "")
                    trailing: Clipboard.copied === modelData.id ? Icons.check : ""
                    onClicked: Clipboard.copy(modelData)
                }
            }

            TextButton { radius: 0;
                text: Icons.trash + "  Clear clipboard"
                onClicked: Clipboard.wipe()
            }
        }
    }

    Component {
        id: mouseC
        ColumnLayout {
            spacing: 8

            ListRow { radius: 0;
                icon: MouseBattery.charging ? Icons.charging : Icons.battery
                title: MouseBattery.level + "%"
                sub: MouseBattery.asleep ? "Asleep (last known level)" : (MouseBattery.charging ? "Charging" : "Mouse battery")
                active: true
                interactive: false
            }

            TextButton { radius: 0; text: Icons.refresh + "  Refresh"; onClicked: MouseBattery.refresh() }
        }
    }

    Component {
        id: windowC
        ColumnLayout {
            spacing: 8

            ListRow { radius: 0;
                icon: Icons.overview
                title: ToplevelManager.activeToplevel?.title || "No active window"
                sub: ToplevelManager.activeToplevel?.appId || ""
                active: true
                interactive: false
            }

            RowLayout {
                Layout.fillWidth: true
                TextButton { radius: 0; text: "Float"; onClicked: Hyprland.dispatch("togglefloating") }
                TextButton { radius: 0; text: "Fullscreen"; onClicked: Hyprland.dispatch("fullscreen") }
                TextButton { radius: 0; text: Icons.close + "  Close"; primary: true; onClicked: Hyprland.dispatch("closewindow") }
            }
        }
    }

    Component {
        id: trayC
        ColumnLayout {
            spacing: 6

            Repeater {
                id: trayRepeater
                model: SystemTray.items

                Rectangle {
                    id: itemRow
                    required property var modelData
                    readonly property bool hasMenu: !!modelData.hasMenu

                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 0
                    color: mouse.containsMouse ? Theme.surface : "transparent"

                    function openMenu() {
                        if (!hasMenu) return;
                        const p = itemRow.mapToItem(null, 0, itemRow.height);
                        menu.anchor.rect.x = p.x;
                        menu.anchor.rect.y = p.y;
                        menu.anchor.rect.width = itemRow.width;
                        menu.anchor.rect.height = 6;
                        menu.open();
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor

                        onClicked: m => {
                            if (m.button === Qt.RightButton || itemRow.modelData.onlyMenu) itemRow.openMenu();
                            else { itemRow.modelData.activate(); BarPopup.close(); }
                        }
                        onWheel: wheel => {
                            const horizontal = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y);
                            itemRow.modelData.scroll(horizontal ? wheel.angleDelta.x : wheel.angleDelta.y, horizontal);
                        }
                    }

                    IconImage {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        source: itemRow.modelData.icon
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 36
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: itemRow.modelData.title || itemRow.modelData.id
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                    }

                    QsMenuAnchor {
                        id: menu
                        menu: itemRow.modelData.menu
                        anchor.window: popup
                        anchor.edges: Edges.Bottom | Edges.Left
                        anchor.gravity: Edges.Bottom | Edges.Right
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: trayRepeater.count === 0
                text: "No tray items"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
