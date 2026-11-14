pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property bool opened: false
    property bool mounted: false
    property string statusText: ""
    property string urlValue: ""

    function normalizeUrl(value: string): string {
        const url = value.trim();
        return /^https?:\/\//i.test(url) ? url : `https://${url}`;
    }

    function websiteHost(value: string): string {
        const url = normalizeUrl(value);
        if (!/^https?:\/\/[^\s/?#]+/i.test(url))
            return "";
        return url.replace(/^[a-z]+:\/\//i, "").split(/[/?#]/)[0].split(":")[0].replace(/^www\./i, "");
    }

    function submit(urlText: string): void {
        const url = normalizeUrl(urlText);
        if (!websiteHost(urlText)) {
            statusText = qsTr("Enter a website address to continue.");
            return;
        }
        statusText = "";
        WebApps.create(suggestedName(url), url, "");
    }

    function suggestedName(url: string): string {
        const host = url.trim()
            .replace(/^[a-z]+:\/\//i, "")
            .split(/[/?#]/)[0]
            .split(":")[0]
            .replace(/^www\./i, "");
        const parts = host.split(".");
        if (parts.length > 2 && ["web", "m", "mobile", "app", "mail"].includes(parts[0].toLowerCase()))
            parts.shift();
        const label = (parts[0] || "").replace(/[-_]+/g, " ").trim();
        return label.replace(/\b\w/g, letter => letter.toUpperCase());
    }

    function open(): void {
        urlValue = "";
        statusText = "";
        iconPreviewTimer.stop();
        WebApps.clearIconPreview();
        opened = true;
    }

    onOpenedChanged: {
        if (opened) {
            closeTimer.stop();
            mounted = true;
        } else {
            iconPreviewTimer.stop();
            WebApps.clearIconPreview();
            closeTimer.restart();
        }
    }

    Timer {
        id: closeTimer
        interval: Appearance.anim.durations.normal
        onTriggered: root.mounted = false
    }

    Timer {
        id: iconPreviewTimer
        interval: 500
        onTriggered: {
            const host = root.websiteHost(root.urlValue);
            if (host.indexOf(".") < 0) {
                WebApps.clearIconPreview();
                return;
            }
            const url = root.normalizeUrl(root.urlValue);
            WebApps.requestIconPreview(url, root.suggestedName(url));
        }
    }

    IpcHandler {
        target: "webApps"
        function toggleCreator(): void {
            if (root.opened)
                root.opened = false;
            else
                root.open();
        }
    }

    Connections {
        target: WebApps
        function onOperationFinished(action: string, success: bool, message: string): void {
            if (action !== "create")
                return;
            if (success) {
                root.opened = false;
                Toaster.toast(qsTr("Web app added"), message, "language");
            } else {
                root.statusText = message;
            }
        }
    }

    Variants {
        model: Quickshell.screens

        StyledWindow {
            id: window
            required property ShellScreen modelData

            screen: modelData
            name: "webapp-creator"
            visible: root.mounted
            onVisibleChanged: if (visible) Qt.callLater(() => urlField.forceActiveFocus())
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            MouseArea {
                anchors.fill: parent
                enabled: root.opened
                onClicked: root.opened = false

                StyledRect {
                    anchors.fill: parent
                    color: "#99000000"
                    opacity: root.opened ? 1 : 0

                    Behavior on opacity {
                        Anim { duration: Appearance.anim.durations.normal }
                    }
                }
            }

            StyledRect {
                id: card
                z: 1
                anchors.centerIn: parent
                width: Math.min(parent.width - Appearance.padding.xl * 2, 500)
                implicitHeight: content.implicitHeight + Appearance.padding.xl * 2
                scale: root.opened ? 1 : 0.94
                radius: Appearance.rounding.large
                color: Colours.palette.m3surfaceContainer
                focus: root.opened
                Keys.onEscapePressed: event => {
                    root.opened = false;
                    event.accepted = true;
                }

                Behavior on scale {
                    Anim { duration: Appearance.anim.durations.normal }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => mouse.accepted = true
                }

                ColumnLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.xl
                    spacing: Appearance.spacing.sm

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: urlField.implicitHeight + Appearance.padding.sm * 2
                        radius: Appearance.rounding.normal
                        color: Colours.tPalette.m3surfaceContainerHigh
                        border.width: urlField.activeFocus ? 1 : 0
                        border.color: Colours.palette.m3primary
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.padding.md
                            anchors.rightMargin: Appearance.padding.md
                            spacing: Appearance.spacing.sm
                            MaterialIcon {
                                text: "language"
                                color: Colours.palette.m3primary
                            }
                            StyledTextField {
                                id: urlField
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                placeholderText: qsTr("Website address")
                                text: root.urlValue
                                font.pointSize: Appearance.font.size.bodyMedium
                                onTextEdited: text => {
                                    root.urlValue = text;
                                    root.statusText = "";
                                    WebApps.clearIconPreview();
                                    iconPreviewTimer.restart();
                                }
                                selectByMouse: true
                                onAccepted: root.submit(urlField.text)
                            }
                            StyledRect {
                                visible: root.websiteHost(urlField.text).length > 0
                                implicitWidth: Math.min(previewName.implicitWidth + Appearance.padding.md * 2 + faviconPreview.implicitWidth + checkIcon.implicitWidth + Appearance.spacing.sm, 160)
                                implicitHeight: 28
                                radius: Appearance.rounding.full
                                color: Colours.palette.m3surfaceContainerHigh
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Appearance.padding.sm
                                    anchors.rightMargin: Appearance.padding.sm
                                    spacing: Appearance.spacing.xs
                                    Image {
                                        id: faviconPreview
                                        Layout.preferredWidth: 18
                                        Layout.preferredHeight: 18
                                        source: WebApps.previewSource ? `file://${WebApps.previewSource}` : ""
                                        sourceSize.width: 36
                                        sourceSize.height: 36
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        visible: status === Image.Ready
                                    }
                                    MaterialIcon {
                                        visible: faviconPreview.status !== Image.Ready
                                        text: "language"
                                        color: Colours.palette.m3onSurfaceVariant
                                        font.pointSize: Appearance.font.size.bodySmall
                                    }
                                    StyledText {
                                        id: previewName
                                        Layout.fillWidth: true
                                        text: WebApps.previewName || root.suggestedName(urlField.text)
                                        color: Colours.palette.m3onSurface
                                        elide: Text.ElideRight
                                    }
                                    MaterialIcon {
                                        id: checkIcon
                                        text: "check_circle"
                                        color: Colours.palette.m3tertiary
                                        font.pointSize: Appearance.font.size.bodySmall
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.xs
                        visible: root.websiteHost(urlField.text).length > 0 || root.statusText.length > 0
                        MaterialIcon {
                            visible: root.statusText.length === 0
                            text: "check_circle"
                            color: Colours.palette.m3tertiary
                            font.pointSize: Appearance.font.size.bodySmall
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: root.statusText.length > 0
                                ? root.statusText
                                : qsTr("Ready to add %1").arg(root.websiteHost(urlField.text))
                            color: root.statusText.length > 0 ? Colours.palette.m3error : Colours.palette.m3tertiary
                            elide: Text.ElideRight
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.sm
                        Item { Layout.fillWidth: true }
                        TextButton {
                            text: qsTr("Cancel")
                            type: TextButton.Text
                            onClicked: root.opened = false
                        }
                        IconTextButton {
                            icon: "arrow_forward"
                            id: submitButton
                            text: WebApps.busy ? qsTr("Adding…") : qsTr("Add to launcher")
                            enabled: !WebApps.busy
                            onClicked: root.submit(urlField.text)
                        }
                    }
                }
            }
        }
    }
}
