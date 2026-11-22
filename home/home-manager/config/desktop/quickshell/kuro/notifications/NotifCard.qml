// Notification card shared by popup alerts and the notification history.
// Layout follows the content supplied by the app and adapts for compact history rows.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.components

Rectangle {
    id: card

    required property var notif
    property bool compact: false
    property bool groupMember: false
    property bool previewOnly: false
    property int refreshTick: 0
    property real progress: 1
    signal expired()

    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    readonly property int timeout: !notif ? 0
        : notif.expireTimeout > 0 ? Math.round(notif.expireTimeout * 1000)
        : critical ? 0 : Config.notifTimeout
    readonly property string image: notif ? Notifications.iconSource(notif.image) : ""
    readonly property string appIcon: notif ? Notifications.iconSource(notif.appIcon) : ""
    readonly property var sourceInfo: notif ? Notifications.sourceInfo(notif) : ({ name: "Notification", icon: "" })
    readonly property string appName: sourceInfo.name
    readonly property bool hasBody: notif && String(notif.body || "").trim() !== ""
    readonly property color priorityColor: critical ? Theme.danger : Theme.border

    implicitHeight: frame.implicitHeight
    opacity: 1
    radius: groupMember ? 0 : Theme.radiusSmall
    color: Theme.surface
    border.width: 1
    border.color: card.priorityColor
    Behavior on border.color { ColorAnimation { duration: 120 } }
    HoverHandler { id: hover }

    NumberAnimation on progress {
        running: !card.compact && card.timeout > 0
        paused: hover.hovered
        from: 1
        to: 0
        duration: card.timeout
        onFinished: card.expired()
    }

    // Clicking the message opens its default action; middle-click dismisses it.
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
        id: frame
        anchors.fill: parent
        spacing: 0

        // App identity, urgency, relative time and dismissal stay on one line.
        RowLayout {
            visible: !card.groupMember
            Layout.fillWidth: true
            Layout.leftMargin: card.compact ? 12 : 11
            Layout.rightMargin: card.compact ? 12 : 11
            Layout.topMargin: card.compact ? 8 : 7
            Layout.bottomMargin: card.compact ? 8 : 7
            spacing: 8

            Item {
                Layout.preferredWidth: card.compact ? 22 : 23
                Layout.preferredHeight: card.compact ? 22 : 23

                Rectangle {
                    anchors.fill: parent
                    color: Theme.bgAlt
                    border.width: 1
                    border.color: Theme.border
                    visible: card.image === "" && (card.appIcon === "" || card.sourceInfo.icon !== "")
                    Text {
                        anchors.centerIn: parent
                        text: card.sourceInfo.icon || card.appName.trim().charAt(0).toUpperCase() || Icons.bell
                        color: card.sourceInfo.icon !== "" ? Theme.text : Theme.accent
                        font.family: Theme.iconFont
                        font.pixelSize: card.sourceInfo.icon !== "" ? (card.compact ? 17 : 19) : (card.compact ? 12 : 14)
                        font.bold: true
                    }
                }
                ClippingRectangle {
                    anchors.fill: parent
                    radius: 0
                    color: Theme.bgAlt
                    visible: card.image !== ""
                    Image {
                        anchors.fill: parent
                        source: card.image
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
                IconImage {
                    visible: card.image === "" && card.appIcon !== "" && card.sourceInfo.icon === ""
                    anchors.fill: parent
                    anchors.margins: 3
                    source: card.appIcon
                }
                Rectangle {
                    visible: card.image !== "" && (card.appIcon !== "" || card.sourceInfo.icon !== "")
                    width: 16
                    height: 16
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.border
                    Text {
                        anchors.centerIn: parent
                        visible: card.sourceInfo.icon !== ""
                        text: card.sourceInfo.icon
                        color: Theme.text
                        font.family: Theme.iconFont
                        font.pixelSize: 11
                    }
                    IconImage {
                        anchors.fill: parent
                        anchors.margins: 2
                        visible: card.sourceInfo.icon === ""
                        source: card.appIcon
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: card.appName
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: card.compact ? 10 : 11
                elide: Text.ElideRight
            }

            Rectangle {
                visible: card.critical
                implicitWidth: importantText.implicitWidth + 10
                implicitHeight: 18
                color: Theme.danger
                Text {
                    id: importantText
                    anchors.centerIn: parent
                    text: "IMPORTANT"
                    color: Theme.bg
                    font.family: Theme.font
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 0.4
                }
            }

            Text {
                text: card.notif ? (card.refreshTick, Notifications.ago(card.notif.timeKey ?? card.notif.id)) : ""
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 10
            }

            Rectangle {
                implicitWidth: 22
                implicitHeight: 22
                color: closeMouse.containsMouse ? Theme.bgAlt : "transparent"
                border.width: closeMouse.containsMouse ? 1 : 0
                border.color: Theme.border
                Text {
                    anchors.centerIn: parent
                    text: Icons.close
                    color: Theme.subtext
                    font.family: Theme.iconFont
                    font.pixelSize: 12
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.dismiss(card.notif)
                }
            }
        }

        // Full-width separator between app metadata and the notification itself.
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
            visible: !card.groupMember
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: card.groupMember ? 12 : 14
            Layout.rightMargin: card.groupMember ? 12 : 14
            Layout.topMargin: card.groupMember ? 7 : card.compact ? 9 : 8
            Layout.bottomMargin: card.groupMember ? 7 : card.compact ? 10 : 9
            spacing: card.groupMember ? 3 : card.compact ? 5 : 4

            RowLayout {
                visible: card.groupMember
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: card.notif ? card.notif.summary : ""
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: card.compact ? Theme.fontSize - 1 : Theme.fontSize
                    font.bold: true
                    wrapMode: card.previewOnly ? Text.NoWrap : Text.Wrap
                    maximumLineCount: card.previewOnly ? 1 : card.compact ? 2 : 3
                    elide: Text.ElideRight
                }

                Text {
                    visible: card.notif !== null
                    text: card.notif ? Notifications.clockTime(card.notif.timeKey ?? card.notif.eventToken) : ""
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 9
                }

                Rectangle {
                    visible: !card.previewOnly
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    color: groupCloseMouse.containsMouse ? Theme.bgAlt : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: Icons.close
                        color: Theme.subtext
                        font.family: Theme.iconFont
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: groupCloseMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.dismiss(card.notif)
                    }
                }
            }

            Text {
                visible: !card.groupMember
                Layout.fillWidth: true
                text: card.notif ? card.notif.summary : ""
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: card.compact ? Theme.fontSize - 1 : Theme.fontSize
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: card.compact ? 2 : 3
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: card.hasBody && !card.previewOnly
                text: card.notif ? card.notif.body : ""
                textFormat: Text.StyledText
                color: Theme.subtext
                linkColor: Theme.link
                font.family: Theme.font
                font.pixelSize: Math.max(11, Theme.fontSize - 3)
                wrapMode: Text.Wrap
                maximumLineCount: card.compact ? 2 : 5
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: card.groupMember ? 12 : 14
            Layout.rightMargin: card.groupMember ? 12 : 14
            visible: !card.previewOnly && card.notif && card.notif.hasInlineReply
            spacing: 6

            InputField {
                id: replyInput
                placeholder: card.notif?.inlineReplyPlaceholder || "Reply…"
                onAccepted: {
                    if (Notifications.sendInlineReply(card.notif, text)) text = "";
                }
            }

            TextButton {
                text: "Send"
                sharp: true
                enabled: replyInput.text.trim() !== ""
                onClicked: {
                    if (Notifications.sendInlineReply(card.notif, replyInput.text)) replyInput.text = "";
                }
            }
        }

        // Notification actions span the whole card and share the available width.
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
            visible: !card.previewOnly && (actionRepeater.count > 0 || (card.notif && card.notif.hasInlineReply))
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 1
            Layout.rightMargin: 1
            Layout.bottomMargin: 1
            visible: !card.previewOnly && actionRepeater.count > 0
            spacing: 0

            Repeater {
                id: actionRepeater
                model: Notifications.actionsOf(card.notif).filter(a => a.identifier !== "default" && a.text !== "" && !(card.notif.hasInlineReply && /reply/i.test(a.identifier)))

                Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: card.compact ? 34 : 36
                    color: index === 0
                        ? (actionMouse.containsMouse ? Theme.mix(Theme.accent, Theme.text, 0.12) : Theme.accent)
                        : actionMouse.containsMouse ? Theme.surface2 : "transparent"

                    Rectangle {
                        visible: index > 0
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: Theme.border
                    }
                    Text {
                        anchors.centerIn: parent
                        width: Math.max(0, parent.width - 12)
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.text
                        color: index === 0 ? Theme.accentFg : Theme.text
                        font.family: Theme.font
                        font.pixelSize: card.compact ? Theme.fontSize - 3 : Theme.fontSize - 2
                        font.bold: index === 0
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.invoke(card.notif, modelData)
                    }
                }
            }
        }
    }

    // Popup expiry progress; history cards stay until dismissed.
    Rectangle {
        visible: !card.compact && card.timeout > 0
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        height: 4
        width: parent.width * card.progress
        color: card.critical ? Theme.danger : Theme.accent
        opacity: 0.8
    }

    // Paint the outline last so action fills and the timer can never cover it.
    Rectangle {
        anchors.fill: parent
        z: 10
        color: "transparent"
        radius: card.radius
        border.width: 1
        border.color: card.priorityColor
        antialiasing: false
    }
}
