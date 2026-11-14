pragma Singleton

import qs.components
import qs.services
import qs.config
import qs.modules.controlcenter
import Quickshell
import QtQuick

Singleton {
    id: root

    function create(parent: Item): void {
        hubWindow.createObject(parent ?? dummy);
    }

    QtObject {
        id: dummy
    }

    Component {
        id: hubWindow

        FloatingWindow {
            id: win

            color: Colours.tPalette.m3surface
            title: qsTr("Monohub")
            implicitWidth: 1180
            implicitHeight: 760
            minimumSize.width: 1180
            minimumSize.height: 760
            maximumSize.width: 1180
            maximumSize.height: 760

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            Session {
                id: session
                root: win
                floating: true
            }

            HubPane {
                anchors.fill: parent
                anchors.margins: Appearance.padding.xl
                session: session
            }
        }
    }
}
