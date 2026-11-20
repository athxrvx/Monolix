// Page shell: scroll area + polling while the page is active.
//   active        : set by ControlCenter (window visible && this page selected)
//   pollInterval  : 0 = no polling
//   opened()      : once each time the page is opened
//   poll()        : periodically while active
// Page content is written directly as children; they automatically go into the ColumnLayout.

import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: root

    property bool active: false
    property bool showScrollIndicator: true
    property int pollInterval: 2000
    readonly property real innerWidth: col.width

    signal opened()
    signal poll()

    default property alias content: col.data

    onActiveChanged: if (active) opened()

    Timer {
        interval: Math.max(500, root.pollInterval)
        repeat: true
        running: root.active && root.pollInterval > 0
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: col
            width: flick.width - 14     // room for the scroll indicator
            spacing: 14
        }
    }

    // Thin scroll indicator
    Rectangle {
        visible: root.showScrollIndicator && flick.contentHeight > flick.height
        anchors.right: parent.right
        width: 3
        radius: 1.5
        color: Theme.surface2
        height: Math.max(24, flick.height * flick.height / Math.max(1, flick.contentHeight))
        y: flick.contentY / Math.max(1, flick.contentHeight - flick.height) * (flick.height - height)
    }
}
