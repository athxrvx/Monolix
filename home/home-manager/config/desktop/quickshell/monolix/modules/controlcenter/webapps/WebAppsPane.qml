pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    anchors.fill: parent

    property string editingId: ""
    property string editName: ""
    property string editUrl: ""
    property string editIcon: ""
    property string removingId: ""
    property string statusText: ""

    function beginEdit(app: var): void {
        editingId = app.id;
        editName = app.name;
        editUrl = app.url;
        editIcon = app.icon || "";
        removingId = "";
        statusText = "";
    }

    Connections {
        target: WebApps
        function onOperationFinished(action: string, success: bool, message: string): void {
            root.statusText = message;
            if (!success)
                return;
            if (action === "update")
                root.editingId = "";
            if (action === "delete")
                root.removingId = "";
        }
    }

    ClippingRectangle {
        id: webAppsClippingRect
        anchors.fill: parent
        anchors.margins: Appearance.padding.md
        anchors.leftMargin: 0
        anchors.rightMargin: Appearance.padding.md

        radius: webAppsBorder.innerRadius
        color: "transparent"

        Loader {
            anchors.fill: parent
            anchors.margins: Appearance.padding.xl + Appearance.padding.md
            anchors.leftMargin: Appearance.padding.xl
            anchors.rightMargin: Appearance.padding.xl

            sourceComponent: webAppsContentComponent
        }
    }

    InnerBorder {
        id: webAppsBorder
        leftThickness: 0
        rightThickness: Appearance.padding.md
    }

    Component {
        id: webAppsContentComponent

        StyledFlickable {
            id: flickable
            anchors.fill: parent
            flickableDirection: Flickable.VerticalFlick
            contentWidth: width
            contentHeight: content.implicitHeight + Appearance.padding.xl * 2

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: flickable
            }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.padding.xl
            spacing: Appearance.spacing.lg

            SectionContainer {
                Layout.fillWidth: true
                alignTop: true
                contentSpacing: Appearance.spacing.md

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Web Apps")
                            font.pointSize: Appearance.font.size.titleMedium
                            font.weight: 500
                        }

                        StyledText {
                            text: WebApps.apps.length === 1 ? qsTr("1 app") : qsTr("%1 apps").arg(WebApps.apps.length)
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        visible: WebApps.apps.length === 0
                        implicitHeight: emptyState.implicitHeight + Appearance.padding.xl * 2
                        radius: Appearance.rounding.normal
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                        ColumnLayout {
                            id: emptyState
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.sm

                            MaterialIcon {
                                Layout.alignment: Qt.AlignHCenter
                                text: "language"
                                font.pointSize: Appearance.font.size.headlineMedium
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: qsTr("No websites added yet")
                                font.pointSize: Appearance.font.size.bodyLarge
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: qsTr("Press Alt + Shift + W to add your first website")
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }

                    Repeater {
                        model: WebApps.apps

                    delegate: StyledRect {
                        id: appCard
                        required property var modelData
                        property bool entered: false

                        Layout.fillWidth: true
                        implicitHeight: cardContent.implicitHeight + Appearance.padding.xl * 2
                        radius: Appearance.rounding.normal
                        color: Colours.palette.m3surfaceContainer
                        clip: true
                        opacity: entered ? 1 : 0
                        scale: entered ? 1 : 0.985

                        Component.onCompleted: Qt.callLater(() => entered = true)

                        Behavior on opacity {
                            Anim { duration: Appearance.anim.durations.normal }
                        }
                        Behavior on scale {
                            Anim { duration: Appearance.anim.durations.normal }
                        }
                        Behavior on implicitHeight {
                            Anim { duration: Appearance.anim.durations.normal }
                        }

                        ColumnLayout {
                            id: cardContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Appearance.padding.xl
                            spacing: Appearance.spacing.md

                            RowLayout {
                                Layout.fillWidth: true
                                visible: root.editingId !== appCard.modelData.id
                                spacing: Appearance.spacing.lg

                                StyledRect {
                                    Layout.preferredWidth: 48
                                    Layout.preferredHeight: 48
                                    radius: Appearance.rounding.normal
                                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: 32
                                        source: Quickshell.iconPath(appCard.modelData.iconPath || "web-browser", "web-browser")
                                        asynchronous: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.xs

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: appCard.modelData.name
                                        font.pointSize: Appearance.font.size.bodyLarge
                                        font.weight: 500
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: appCard.modelData.url
                                        color: Colours.palette.m3onSurfaceVariant
                                        elide: Text.ElideMiddle
                                    }
                                }

                                TextButton {
                                    text: qsTr("Open")
                                    type: TextButton.Filled
                                    onClicked: WebApps.launch(appCard.modelData.id)
                                }

                                TextButton {
                                    text: qsTr("Edit")
                                    type: TextButton.Tonal
                                    onClicked: root.beginEdit(appCard.modelData)
                                }

                                TextButton {
                                    text: qsTr("Remove")
                                    type: TextButton.Text
                                    onClicked: {
                                        root.removingId = appCard.modelData.id;
                                        root.editingId = "";
                                        root.statusText = "";
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: root.editingId === appCard.modelData.id
                                spacing: Appearance.spacing.md

                                StyledText {
                                    text: qsTr("Edit website")
                                    font.pointSize: Appearance.font.size.bodyMedium
                                }

                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: editNameField.implicitHeight + Appearance.padding.lg * 2
                                    radius: Appearance.rounding.normal
                                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                                    StyledTextField {
                                        id: editNameField
                                        anchors.fill: parent
                                        anchors.margins: Appearance.padding.lg
                                        placeholderText: qsTr("App name")
                                        text: root.editName
                                        onTextEdited: text => root.editName = text
                                    }
                                }

                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: editUrlField.implicitHeight + Appearance.padding.lg * 2
                                    radius: Appearance.rounding.normal
                                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                                    StyledTextField {
                                        id: editUrlField
                                        anchors.fill: parent
                                        anchors.margins: Appearance.padding.lg
                                        placeholderText: qsTr("https://example.com")
                                        text: root.editUrl
                                        onTextEdited: text => root.editUrl = text
                                    }
                                }

                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: editIconField.implicitHeight + Appearance.padding.lg * 2
                                    radius: Appearance.rounding.normal
                                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                                    StyledTextField {
                                        id: editIconField
                                        anchors.fill: parent
                                        anchors.margins: Appearance.padding.lg
                                        placeholderText: qsTr("Custom icon image URL · optional")
                                        text: root.editIcon
                                        onTextEdited: text => root.editIcon = text
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Item { Layout.fillWidth: true }

                                    TextButton {
                                        text: qsTr("Cancel")
                                        type: TextButton.Text
                                        onClicked: root.editingId = ""
                                    }

                                    TextButton {
                                        text: WebApps.busy ? qsTr("Saving…") : qsTr("Save changes")
                                        type: TextButton.Filled
                                        enabled: !WebApps.busy
                                        onClicked: WebApps.update(appCard.modelData.id, root.editName.trim(), root.editUrl.trim(), root.editIcon.trim())
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: root.removingId === appCard.modelData.id
                                spacing: Appearance.spacing.md

                                StyledText {
                                    Layout.fillWidth: true
                                    text: qsTr("Remove %1 from your launcher?").arg(appCard.modelData.name)
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                TextButton {
                                    text: qsTr("Cancel")
                                    type: TextButton.Text
                                    onClicked: root.removingId = ""
                                }

                                TextButton {
                                    text: WebApps.busy ? qsTr("Removing…") : qsTr("Remove website")
                                    type: TextButton.Filled
                                    enabled: !WebApps.busy
                                    onClicked: WebApps.remove(appCard.modelData.id)
                                }
                            }
                        }
                    }
                }

                    StyledRect {
                        Layout.fillWidth: true
                        visible: root.statusText.length > 0
                        implicitHeight: statusLabel.implicitHeight + Appearance.padding.lg * 2
                        radius: Appearance.rounding.normal
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                        StyledText {
                            id: statusLabel
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Appearance.padding.lg
                            text: root.statusText
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.Wrap
                        }
                    }
            }
        }
        }
    }
}
