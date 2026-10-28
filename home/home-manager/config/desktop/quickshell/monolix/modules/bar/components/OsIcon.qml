pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.components.effects
import qs.config
import qs.services
import qs.utils

Item {
    id: root

    required property var visibilities

    implicitWidth: Math.round(Appearance.font.size.bodyLarge * 1.6)
    implicitHeight: Math.round(Appearance.font.size.bodyLarge * 1.6)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.visibilities.launcher = !root.visibilities.launcher
    }

    Loader {
        anchors.centerIn: parent
        width: root.implicitWidth
        height: root.implicitHeight
        asynchronous: true
        sourceComponent: SysInfo.isDefaultLogo ? monolixLogo : distroLogo

        Component {
            id: distroLogo

            ColouredIcon {
                width: root.implicitWidth
                height: root.implicitHeight
                implicitSize: root.implicitWidth
                source: SysInfo.osLogo
                colour: Colours.palette.m3tertiary
            }
        }

        Component {
            id: monolixLogo

            Logo {
                width: root.implicitWidth
                height: root.implicitHeight
            }
        }
    }
}
