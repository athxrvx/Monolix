// Single-line text field with a placeholder and optional icon.

import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property string icon: ""
    property bool password: false
    property color borderColor: Theme.border
    property color focusedBorderColor: Theme.subtext
    readonly property bool focused: input.activeFocus

    signal accepted()

    function forceFocus() { input.forceActiveFocus(); }

    Layout.fillWidth: true
    implicitHeight: 32
    radius: Theme.radiusSmall
    color: Theme.surface
    border.color: input.activeFocus ? root.focusedBorderColor : root.borderColor
    Behavior on border.color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Text {
            visible: root.icon !== ""
            text: root.icon
            color: Theme.muted
            font.family: Theme.iconFont
            font.pixelSize: 16
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextInput {
                id: input
                anchors.fill: parent
                z: 0
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                selectionColor: Theme.selectionBg
                selectedTextColor: Theme.selectionFg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                echoMode: root.password ? TextInput.Password : TextInput.Normal
                selectByMouse: true
                clip: true
                onAccepted: root.accepted()
            }

            Text {
                anchors.fill: parent
                z: 0
                verticalAlignment: Text.AlignVCenter
                visible: input.text === ""
                enabled: false
                text: root.placeholder
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                elide: Text.ElideRight
            }

            // PopupWindow focus grabs can leave an empty TextInput hard to
            // click on some compositors. A non-exclusive tap handler ensures
            // focus without intercepting TextInput's caret and selection input.
            TapHandler {
                gesturePolicy: TapHandler.WithinBounds
                onTapped: input.forceActiveFocus()
            }
        }
    }
}
