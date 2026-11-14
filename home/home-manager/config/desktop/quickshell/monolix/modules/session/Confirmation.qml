pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property string icon
    required property string title
    required property string message
    required property string actionText

    signal cancelled()
    signal confirmed()

    implicitWidth: 340
    implicitHeight: content.implicitHeight + Appearance.padding.xl * 2
    radius: Appearance.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => cancelButton.forceActiveFocus());
    }
    Keys.onEscapePressed: event => {
        root.cancelled();
        event.accepted = true;
    }

    ColumnLayout {
        id: content

        anchors.centerIn: parent
        width: parent.width - Appearance.padding.xl * 2
        spacing: Appearance.spacing.lg

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.headlineLarge
        }

        StyledText {
            Layout.fillWidth: true
            text: root.title
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pointSize: Appearance.font.size.titleMedium
        }

        StyledText {
            Layout.fillWidth: true
            text: root.message
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Colours.palette.m3onSurfaceVariant
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.md

            ChoiceButton {
                id: cancelButton

                Layout.fillWidth: true
                text: qsTr("Cancel")
                KeyNavigation.right: confirmButton
                KeyNavigation.tab: confirmButton
                KeyNavigation.backtab: confirmButton
                onClicked: root.cancelled()
            }

            ChoiceButton {
                id: confirmButton

                Layout.fillWidth: true
                text: root.actionText
                KeyNavigation.left: cancelButton
                KeyNavigation.tab: cancelButton
                KeyNavigation.backtab: cancelButton
                onClicked: root.confirmed()
            }
        }
    }

    component ChoiceButton: StyledRect {
        id: button

        required property string text
        signal clicked()

        implicitWidth: label.implicitWidth + Appearance.padding.lg * 2
        implicitHeight: label.implicitHeight + Appearance.padding.md * 2
        radius: Appearance.rounding.normal
        color: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh

        Keys.onReturnPressed: event => {
            if (!event.isAutoRepeat)
                button.clicked();
            event.accepted = true;
        }
        Keys.onEnterPressed: event => {
            if (!event.isAutoRepeat)
                button.clicked();
            event.accepted = true;
        }
        Keys.onSpacePressed: event => {
            if (!event.isAutoRepeat)
                button.clicked();
            event.accepted = true;
        }

        StateLayer {
            radius: parent.radius
            color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

            function onClicked(): void {
                button.clicked();
            }
        }

        StyledText {
            id: label

            anchors.centerIn: parent
            text: button.text
            color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        }
    }
}
