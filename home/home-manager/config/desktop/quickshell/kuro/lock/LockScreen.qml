// Secure Wayland session lock with PAM authentication and a blurred wallpaper.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

Item {
    id: root

    readonly property bool locked: sessionLock.locked
    readonly property bool readyForPassword: sessionLock.locked && pam.responseRequired && !authenticating
    property string status: ""
    property bool authenticating: false
    property date now: new Date()

    function lock() {
        if (sessionLock.locked) return;
        status = "";
        authenticating = false;
        Wallpaper.refresh();
        sessionLock.locked = true;
        Qt.callLater(startPam);
    }

    function startPam() {
        if (!sessionLock.locked || pam.active) return;
        if (!pam.start()) status = "Could not start password authentication";
    }

    function submitPassword(password) {
        if (!readyForPassword || password === "") return;
        authenticating = true;
        status = "Verifying…";
        pam.respond(password);
    }

    Timer {
        interval: 1000
        repeat: true
        running: sessionLock.locked
        onTriggered: root.now = new Date()
    }

    Timer {
        id: retryTimer
        interval: 250
        onTriggered: root.startPam()
    }

    PamContext {
        id: pam
        config: "login"

        onCompleted: result => {
            root.authenticating = false;
            if (result === PamResult.Success) {
                root.status = "";
                sessionLock.locked = false;
                return;
            }

            root.status = result === PamResult.Failed
                ? "Incorrect password. Try again."
                : "Authentication failed. Try again.";
            retryTimer.restart();
        }

        onError: error => {
            root.authenticating = false;
            root.status = "Password service error: " + PamError.toString(error);
            retryTimer.restart();
        }
    }

    WlSessionLock {
        id: sessionLock

        surface: Component {
            WlSessionLockSurface {
                id: lockSurface
                color: Theme.bg

                readonly property bool preferredInputScreen: Hyprland.focusedMonitor
                    ? screen?.name === Hyprland.focusedMonitor.name
                    : screen === Quickshell.screens[0]

                Image {
                    id: wallpaper
                    anchors.fill: parent
                    source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: parent.width
                    sourceSize.height: parent.height
                    visible: status === Image.Ready
                }

                MultiEffect {
                    anchors.fill: wallpaper
                    source: wallpaper
                    visible: wallpaper.status === Image.Ready
                    blurEnabled: true
                    blur: 0.88
                    blurMax: 56
                    autoPaddingEnabled: false
                    saturation: -0.25
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#99000000"
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(420, parent.width - 40)
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDateTime(root.now, "dddd, d MMMM")
                        color: "#d9ffffff"
                        font.family: Theme.font
                        font.pixelSize: 16
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDateTime(root.now, "hh:mm")
                        color: "#ffffff"
                        font.family: Theme.font
                        font.pixelSize: 64
                        font.weight: Font.Light
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 18
                        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.94)
                        border.width: 1
                        border.color: "#55ffffff"
                        implicitHeight: card.implicitHeight + 32

                        ColumnLayout {
                            id: card
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 10

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: "Welcome back"
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 17
                                font.bold: true
                            }

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: pam.responseRequired ? (pam.message || "Enter your password")
                                                           : "Starting secure authentication…"
                                color: Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                InputField {
                                    id: passwordInput
                                    Layout.fillWidth: true
                                    enabled: root.readyForPassword
                                    password: !pam.responseVisible
                                    placeholder: "Password"
                                    radius: 0
                                    onAccepted: {
                                        const secret = text;
                                        text = "";
                                        root.submitPassword(secret);
                                    }
                                }

                                TextButton {
                                    text: root.authenticating ? "…" : "Unlock"
                                    primary: true
                                    radius: 0
                                    enabled: root.readyForPassword && passwordInput.text !== ""
                                    onClicked: {
                                        const secret = passwordInput.text;
                                        passwordInput.text = "";
                                        root.submitPassword(secret);
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: root.status !== ""
                                horizontalAlignment: Text.AlignHCenter
                                text: root.status
                                color: root.status.startsWith("Incorrect") ? Theme.danger : Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 14
                        horizontalAlignment: Text.AlignHCenter
                        text: Quickshell.env("USER") + "  ·  locked"
                        color: "#caffffff"
                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                }

                Component.onCompleted: {
                    if (preferredInputScreen) Qt.callLater(() => passwordInput.forceFocus());
                }

                Connections {
                    target: root
                    function onReadyForPasswordChanged() {
                        if (root.readyForPassword && lockSurface.preferredInputScreen)
                            Qt.callLater(() => passwordInput.forceFocus());
                    }
                }
            }
        }
    }
}
