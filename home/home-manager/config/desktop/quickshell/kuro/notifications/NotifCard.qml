// A single notification card. Used by both popups and the notification center.
//   compact: true = list version (no timer, no shadow)

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.config
import qs.components
import qs.services

Rectangle {
    id: card

    required property var notif
    property bool compact: false
    property int refreshTick: 0          // incremented periodically to refresh relative time labels

    // Popup: dismisses itself after the timeout, pauses while hovered
    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    // Quickshell exposes the D-Bus timeout in seconds; NumberAnimation uses ms.
    readonly property int timeout: !notif ? 0
        : notif.expireTimeout > 0 ? Math.round(notif.expireTimeout * 1000)
        : critical ? 0 : Config.notifTimeout
    property real progress: 1
    signal expired()

    readonly property string image: notif ? Notifications.iconSource(notif.image) : ""
    readonly property string appIcon: notif ? Notifications.iconSource(notif.appIcon) : ""

    implicitHeight: col.implicitHeight + (compact ? 20 : 24)
    radius: Theme.radiusSmall
    color: hover.hovered ? Theme.surface2 : Theme.surface
    border.width: 1
    border.color: critical ? Theme.danger : hover.hovered ? Theme.accent : Theme.border
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    HoverHandler { id: hover }

    // Hitung mundur popup
    NumberAnimation on progress {
        id: countdown
        running: !card.compact && card.timeout > 0
        paused: hover.hovered
        from: 1; to: 0
        duration: card.timeout
        onFinished: card.expired()
    }

    // Clicking the card body triggers the default action
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) Notifications.dismiss(card.notif);
            else Notifications.activate(card.notif);
        }
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: compact ? 12 : 14
        spacing: compact ? 9 : 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            // Notification image (e.g. avatar) or app icon
            Item {
                Layout.preferredWidth: compact ? 36 : 42
                Layout.preferredHeight: compact ? 36 : 42
                Layout.alignment: Qt.AlignTop

                Rectangle {
                    anchors.fill: parent
                    radius: 0
                    color: Theme.surface2
                    border.width: 1
                    border.color: Theme.border
                    visible: card.image === "" && card.appIcon === ""

                    Text {
                        anchors.centerIn: parent
                        text: Icons.bell
                        color: Theme.accent
                        font.family: Theme.iconFont
                        font.pixelSize: 22
                    }
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 0
                    color: "transparent"
                    visible: card.image !== ""

                    Image {
                        anchors.fill: parent
                        source: card.image
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                IconImage {
                    visible: card.image === "" && card.appIcon !== ""
                    anchors.fill: parent
                    anchors.margins: 4
                    source: card.appIcon
                }

                // Small app icon in the corner when an image is present
                IconImage {
                    visible: card.image !== "" && card.appIcon !== ""
                    width: 16; height: 16
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: -4
                    source: card.appIcon
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: card.notif ? (card.notif.appName || "") : ""
                        visible: !card.compact && text !== ""
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 11
                        font.letterSpacing: 0.7
                        font.capitalization: Font.AllUppercase
                        elide: Text.ElideRight
                    }
                    Text {
                        text: card.notif ? (card.refreshTick, Notifications.ago(card.notif.id)) : ""
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 11
                    }
                    IconButton {
                        icon: Icons.close
                        size: 20
                        iconColor: Theme.muted
                        onClicked: Notifications.dismiss(card.notif)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: card.notif ? card.notif.summary : ""
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Math.max(12, Theme.fontSize - (card.compact ? 2 : 1))
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.notif ? card.notif.body : ""
                    textFormat: Text.StyledText
                    color: Theme.subtext
                    linkColor: Theme.link
                    font.family: Theme.font
                    font.pixelSize: Math.max(11, Theme.fontSize - (card.compact ? 3 : 2))
                    wrapMode: Text.Wrap
                    maximumLineCount: card.compact ? 2 : 4
                    elide: Text.ElideRight
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }
        }

        // Action buttons (besides the default one)
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 52
            spacing: 6
            visible: actionRepeater.count > 0

            Repeater {
                id: actionRepeater
                model: Notifications.actionsOf(card.notif).filter(a => a.identifier !== "default")

                TextButton {
                    required property var modelData
                    text: modelData.text
                    onClicked: Notifications.invoke(card.notif, modelData)
                }
            }
        }
    }

    // Popup remaining-time bar
    Rectangle {
        visible: !card.compact && card.timeout > 0
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: card.radius
        height: 3
        radius: 0
        width: (parent.width - card.radius * 2) * card.progress
        color: card.critical ? Theme.danger : Theme.accent
        opacity: 0.82
    }
}
