import qs.components
import qs.services
import qs.config
import Quickshell.Services.SystemTray
import QtQuick

Item {
    id: root

    readonly property alias items: items
    property bool expanded: false
    readonly property int buttonSize: 40
    readonly property int menuPadding: Appearance.padding.xs
    readonly property color buttonBackground: Qt.alpha(
        Colours.tPalette.m3surfaceContainer,
        Config.bar.tray.background ? Colours.tPalette.m3surfaceContainer.a : 0
    )

    visible: items.count > 0
    implicitWidth: buttonSize
    implicitHeight: buttonSize + menuSlot.implicitHeight

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 0

        StyledRect {
            id: toggleButton

            width: root.buttonSize
            height: root.buttonSize
            radius: Appearance.rounding.normal
            color: root.buttonBackground

            StateLayer {
                color: root.expanded ? Colours.palette.m3primary : Colours.palette.m3onSurface
                radius: toggleButton.radius

                function onClicked(): void {
                    root.expanded = !root.expanded;
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: "expand_more"
                color: root.expanded ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.bodyLarge
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim { easing.bezierCurve: Appearance.anim.curves.emphasized }
                }
            }
        }

        Item {
            id: menuSlot

            width: root.buttonSize
            implicitHeight: root.expanded && items.count > 0
                ? Appearance.spacing.sm + menu.implicitHeight
                : 0
            height: implicitHeight
            visible: items.count > 0 && (root.expanded || height > 0)
            clip: true

            Behavior on implicitHeight {
                Anim { easing.bezierCurve: Appearance.anim.curves.emphasized }
            }

            StyledRect {
                id: menu
                anchors.top: parent.top
                anchors.topMargin: Appearance.spacing.sm
                width: root.buttonSize
                implicitHeight: trayItems.implicitHeight + root.menuPadding * 2
                height: implicitHeight
                radius: Appearance.rounding.large
                color: Colours.tPalette.m3surfaceContainer
                opacity: root.expanded ? 1 : 0
                enabled: root.expanded

                Behavior on opacity {
                    Anim { easing.bezierCurve: Appearance.anim.curves.emphasized }
                }

                Column {
                    id: trayItems

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: root.menuPadding
                    spacing: Appearance.spacing.xs

                    Repeater {
                        id: items

                        model: SystemTray.items
                        TrayItem {}
                    }
                }
            }
        }
    }
}
