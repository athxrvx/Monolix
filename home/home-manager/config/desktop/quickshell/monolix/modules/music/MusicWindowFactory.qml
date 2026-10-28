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
        musicWindow.createObject(parent ?? dummy);
    }

    QtObject {
        id: dummy
    }

    Component {
        id: musicWindow

        FloatingWindow {
            id: win

            color: Colours.tPalette.m3surface
            title: qsTr("Music")
            implicitWidth: 900
            implicitHeight: 620
            minimumSize.width: 900
            minimumSize.height: 620
            maximumSize.width: 900
            maximumSize.height: 620

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            Session {
                id: session
                root: win
                floating: true
            }

            MusicPane {
                anchors.fill: parent
                anchors.margins: Appearance.padding.xl
                session: session
            }
        }
    }
}
