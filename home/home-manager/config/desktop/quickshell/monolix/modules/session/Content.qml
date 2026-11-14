pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities
    property Item pendingAction: null

    implicitWidth: pendingAction ? confirmation.implicitWidth + Appearance.padding.xl * 2 : actions.implicitWidth
    implicitHeight: pendingAction ? confirmation.implicitHeight + Appearance.padding.xl * 2 : actions.implicitHeight

    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left

    function requestAction(button: Item): void {
        if (!pendingAction)
            pendingAction = button;
    }

    function cancelAction(): void {
        const button = pendingAction;
        pendingAction = null;
        if (button && visibilities.session)
            button.forceActiveFocus();
    }

    function confirmAction(): void {
        if (!pendingAction)
            return;

        const command = Array.from(pendingAction.command);
        pendingAction = null;
        visibilities.session = false;
        Quickshell.execDetached(command);
    }

    Connections {
        target: root.visibilities

        function onSessionChanged(): void {
            if (root.visibilities.session)
                logout.forceActiveFocus();
            else
                root.pendingAction = null;
        }

        function onLauncherChanged(): void {
            if (root.visibilities.session && !root.visibilities.launcher && !root.pendingAction)
                logout.forceActiveFocus();
        }
    }

    Confirmation {
        id: confirmation

        anchors.centerIn: parent
        visible: root.pendingAction !== null
        icon: root.pendingAction?.icon ?? ""
        title: root.pendingAction?.confirmationTitle ?? ""
        message: root.pendingAction?.confirmationMessage ?? ""
        actionText: root.pendingAction?.actionText ?? ""
        onCancelled: root.cancelAction()
        onConfirmed: root.confirmAction()
    }

    Column {
        id: actions

        anchors.centerIn: parent
        visible: !root.pendingAction
        padding: Appearance.padding.xl
        spacing: Appearance.spacing.xxl

        SessionButton {
            id: logout

            icon: "logout"
            command: Config.session.commands.logout
            actionText: qsTr("Log out")
            confirmationTitle: qsTr("Log out?")
            confirmationMessage: qsTr("This will end your session. Unsaved work may be lost.")

            KeyNavigation.down: shutdown
        }

        SessionButton {
            id: shutdown

            icon: "power_settings_new"
            command: Config.session.commands.shutdown
            actionText: qsTr("Shut down")
            confirmationTitle: qsTr("Shut down?")
            confirmationMessage: qsTr("This will turn off your computer. Unsaved work may be lost.")

            KeyNavigation.up: logout
            KeyNavigation.down: hibernate
        }

        AnimatedImage {
            width: Config.session.sizes.button
            height: Config.session.sizes.button
            sourceSize.width: width
            sourceSize.height: height

            playing: visible
            asynchronous: true
            speed: 0.7
            source: Paths.absolutePath(Config.paths.sessionGif)
        }

        SessionButton {
            id: hibernate

            icon: "downloading"
            command: Config.session.commands.hibernate
            actionText: qsTr("Hibernate")
            confirmationTitle: qsTr("Hibernate?")
            confirmationMessage: qsTr("This will save your session to disk and power down the computer.")

            KeyNavigation.up: shutdown
            KeyNavigation.down: reboot
        }

        SessionButton {
            id: reboot

            icon: "cached"
            command: Config.session.commands.reboot
            actionText: qsTr("Restart")
            confirmationTitle: qsTr("Restart?")
            confirmationMessage: qsTr("This will restart your computer. Unsaved work may be lost.")

            KeyNavigation.up: hibernate
        }
    }

    component SessionButton: StyledRect {
        id: button

        required property string icon
        required property list<string> command
        required property string actionText
        required property string confirmationTitle
        required property string confirmationMessage

        implicitWidth: Config.session.sizes.button
        implicitHeight: Config.session.sizes.button

        radius: Appearance.rounding.large
        color: button.activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

        Keys.onEnterPressed: event => {
            if (!event.isAutoRepeat)
                root.requestAction(button);
            event.accepted = true;
        }
        Keys.onReturnPressed: event => {
            if (!event.isAutoRepeat)
                root.requestAction(button);
            event.accepted = true;
        }
        Keys.onEscapePressed: root.visibilities.session = false
        Keys.onPressed: event => {
            // ...existing code...
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if (event.key === Qt.Key_K && KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            }
        }

        StateLayer {
            radius: parent.radius
            color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

            function onClicked(): void {
                root.requestAction(button);
            }
        }

        MaterialIcon {
            anchors.centerIn: parent

            text: button.icon
            color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            font.pointSize: Appearance.font.size.headlineLarge
            font.weight: 500
        }
    }
}
