pragma ComponentBehavior: Bound

import ".."
import "../components"
import "."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.config
import qs.services
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

SplitPaneWithDetails {
    id: root

    required property Session session

    anchors.fill: parent
    activeItem: session.crossDeviceActive
    paneIdGenerator: function (device) {
        return device ? device.id : "";
    }

    leftContent: Component {
        StyledFlickable {
            id: leftFlickable

            flickableDirection: Flickable.VerticalFlick
            contentHeight: deviceList.implicitHeight

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: leftFlickable
            }

            DeviceList {
                id: deviceList

                anchors.left: parent.left
                anchors.right: parent.right
                title: qsTr("Devices (%1)").arg(KdeConnect.devices.length)
                description: qsTr("Connect your phone and other devices")
                activeItem: root.session.crossDeviceActive

                model: ScriptModel {
                    values: [...KdeConnect.devices].sort((a, b) => (b.paired - a.paired) || (b.reachable - a.reachable) || a.name.localeCompare(b.name))
                }

                headerComponent: Component {
                    RowLayout {
                        spacing: Appearance.spacing.md

                        StyledText {
                            text: qsTr("Cross Device")
                            font.pointSize: Appearance.font.size.titleMedium
                            font.weight: 500
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        TextButton {
                            text: KdeConnect.refreshing ? qsTr("Searching…") : qsTr("Refresh")
                            enabled: !KdeConnect.refreshing
                            type: TextButton.Tonal
                            onClicked: KdeConnect.refresh()
                        }
                    }
                }

                delegate: Component {
                    StyledRect {
                        id: deviceRow

                        required property var modelData

                        width: ListView.view ? ListView.view.width : undefined
                        implicitHeight: rowContent.implicitHeight + Appearance.padding.md * 2
                        color: Qt.alpha(Colours.tPalette.m3surfaceContainer, root.session.crossDeviceActiveId === modelData.id ? Colours.tPalette.m3surfaceContainer.a : 0)
                        radius: Appearance.rounding.normal

                        StateLayer {
                            function onClicked(): void {
                                root.session.crossDeviceActiveId = deviceRow.modelData.id;
                            }
                        }

                        RowLayout {
                            id: rowContent

                            anchors.fill: parent
                            anchors.margins: Appearance.padding.md
                            spacing: Appearance.spacing.lg

                            StyledRect {
                                implicitWidth: 44
                                implicitHeight: 44
                                radius: Appearance.rounding.normal
                                color: deviceRow.modelData.paired ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "smartphone"
                                    color: deviceRow.modelData.paired ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                    font.pointSize: Appearance.font.size.titleMedium
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.xs

                                StyledText {
                                    Layout.fillWidth: true
                                    text: deviceRow.modelData.name
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: deviceRow.modelData.paired
                                        ? (deviceRow.modelData.reachable ? qsTr("Paired · connected") : qsTr("Paired · offline"))
                                        : (deviceRow.modelData.reachable ? qsTr("Nearby · not paired") : qsTr("Not connected"))
                                    color: Colours.palette.m3outline
                                    font.pointSize: Appearance.font.size.labelLarge
                                    elide: Text.ElideRight
                                }
                            }

                            MaterialIcon {
                                visible: deviceRow.modelData.paired && deviceRow.modelData.reachable
                                text: "check_circle"
                                color: Colours.palette.m3primary
                                font.pointSize: Appearance.font.size.bodyLarge
                            }
                        }
                    }
                }
            }
        }
    }

    rightDetailsComponent: Component {
        StyledFlickable {
            id: detailsFlickable

            required property Session session
            session: root.session
            readonly property var device: session.crossDeviceActive

            flickableDirection: Flickable.VerticalFlick
            contentHeight: detailsContent.implicitHeight

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: detailsFlickable
            }

            ColumnLayout {
                id: detailsContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Appearance.spacing.lg

                SettingsHeader {
                    Layout.fillWidth: true
                    icon: "smartphone"
                    title: detailsFlickable.device?.name ?? ""
                }

                StyledText {
                    Layout.topMargin: Appearance.spacing.md
                    text: qsTr("Device status")
                    font.pointSize: Appearance.font.size.bodyLarge
                    font.weight: 500
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: statusContent.implicitHeight + Appearance.padding.xl * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    ColumnLayout {
                        id: statusContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.xl
                        spacing: Appearance.spacing.md

                        StyledText {
                            Layout.fillWidth: true
                            text: detailsFlickable.device?.paired
                                ? (detailsFlickable.device.reachable ? qsTr("Paired and connected") : qsTr("Paired, but offline"))
                                : (detailsFlickable.device?.reachable ? qsTr("Nearby and ready to pair") : qsTr("Not connected"))
                            font.pointSize: Appearance.font.size.bodyLarge
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: detailsFlickable.device?.id ?? ""
                            color: Colours.palette.m3onSurfaceVariant
                            elide: Text.ElideMiddle
                        }
                    }
                }

                StyledText {
                    Layout.topMargin: Appearance.spacing.md
                    text: qsTr("Actions")
                    font.pointSize: Appearance.font.size.bodyLarge
                    font.weight: 500
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.sm

                    TextButton {
                        visible: !detailsFlickable.device?.paired
                        enabled: detailsFlickable.device?.reachable ?? false
                        text: qsTr("Pair")
                        type: TextButton.Tonal
                        onClicked: KdeConnect.runAction(detailsFlickable.device.id, "--pair")
                    }

                    TextButton {
                        visible: detailsFlickable.device?.paired && detailsFlickable.device?.reachable
                        text: qsTr("Ping")
                        type: TextButton.Tonal
                        onClicked: KdeConnect.runAction(detailsFlickable.device.id, "--ping")
                    }

                    TextButton {
                        visible: detailsFlickable.device?.paired && detailsFlickable.device?.reachable
                        text: qsTr("Ring")
                        type: TextButton.Text
                        onClicked: KdeConnect.runAction(detailsFlickable.device.id, "--ring")
                    }

                    TextButton {
                        visible: detailsFlickable.device?.paired
                        text: qsTr("Unpair")
                        type: TextButton.Text
                        onClicked: KdeConnect.runAction(detailsFlickable.device.id, "--unpair")
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: KdeConnect.statusText
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    rightSettingsComponent: Component {
        StyledFlickable {
            id: overviewFlickable

            required property Session session
            session: root.session

            flickableDirection: Flickable.VerticalFlick
            contentHeight: overviewContent.implicitHeight

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: overviewFlickable
            }

            ColumnLayout {
                id: overviewContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Appearance.spacing.lg

                SettingsHeader {
                    Layout.fillWidth: true
                    icon: "devices"
                    title: qsTr("Cross Device")
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: overviewText.implicitHeight + Appearance.padding.xl * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    StyledText {
                        id: overviewText
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.xl
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                        text: qsTr("Pair a phone or another device running KDE Connect. Make sure both devices are on the same network, then refresh the list.")
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: KdeConnect.statusText
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
