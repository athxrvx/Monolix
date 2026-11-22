// End4-style app group: one shared header, two compact message previews,
// then full individual notification content when expanded.

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

Rectangle {
    id: root

    required property var group
    property int refreshTick: 0

    readonly property int totalCount: group.items.length
    readonly property bool expanded: Notifications.isGroupExpanded(group.key)

    function toggleExpanded() {
        Notifications.toggleGroup(group.key)
    }

    implicitHeight: content.implicitHeight + 2
    Behavior on implicitHeight {
        NumberAnimation {
            duration: Math.min(10, root.totalCount) * 36
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1]
        }
    }
    color: Theme.surface
    border.width: 1
    border.color: Theme.border
    clip: true

    ColumnLayout {
        id: content
        width: parent.width
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 8
            Layout.topMargin: 8
            Layout.bottomMargin: 7
            spacing: 8

            Item {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22

                Rectangle {
                    anchors.fill: parent
                    visible: root.group.icon === "" && root.group.appIcon === ""
                    color: Theme.bgAlt
                    border.width: 1
                    border.color: Theme.border
                    Text {
                        anchors.centerIn: parent
                        text: String(root.group.app || "?").trim().charAt(0).toUpperCase()
                        color: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
                Text {
                    anchors.fill: parent
                    visible: root.group.icon !== ""
                    text: root.group.icon
                    color: Theme.text
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                IconImage {
                    anchors.fill: parent
                    anchors.margins: 2
                    visible: root.group.icon === "" && root.group.appIcon !== ""
                    source: Notifications.iconSource(root.group.appIcon)
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.group.app
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                text: (root.refreshTick, Notifications.ago(root.group.latestToken))
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 9
            }

            Rectangle {
                visible: root.totalCount > 1
                implicitWidth: countLabel.implicitWidth + 12
                implicitHeight: 20
                color: Theme.bgAlt
                border.width: 1
                border.color: Theme.border
                Text {
                    id: countLabel
                    anchors.centerIn: parent
                    text: String(root.totalCount)
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: 9
                }
            }

            TextButton {
                visible: root.totalCount > 1
                text: root.expanded ? "LESS" : "MORE"
                sharp: true
                flat: true
                onClicked: root.toggleExpanded()
            }

            TextButton {
                text: Icons.close
                sharp: true
                flat: true
                onClicked: Notifications.clearGroup(root.group)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.topMargin: 9
            Layout.bottomMargin: 9
            spacing: root.expanded ? 5 : 3

            Repeater {
                model: root.expanded
                    ? root.group.items
                    : root.group.items.slice(0, Math.min(2, root.totalCount))

                NotifCard {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    notif: modelData
                    compact: true
                    groupMember: true
                    previewOnly: !root.expanded
                    refreshTick: root.refreshTick
                }
            }
        }
    }
}
