// Minimal blurred-wallpaper Wayland session lock with PAM authentication.
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
                color: "#0d0d0d"

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
                    width: Math.min(360, parent.width - 48)
                    spacing: 8

                    InputField {
                        id: passwordInput
                        Layout.fillWidth: true
                        enabled: root.readyForPassword
                        password: !pam.responseVisible
                        placeholder: ""
                        borderColor: Theme.accent
                        focusedBorderColor: Theme.accent
                        radius: 0
                        onAccepted: {
                            const secret = text;
                            text = "";
                            root.submitPassword(secret);
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.status !== ""
                        horizontalAlignment: Text.AlignHCenter
                        text: root.status
                        color: root.status.startsWith("Incorrect") ? Theme.danger : "#888888"
                        font.family: Theme.font
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
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
