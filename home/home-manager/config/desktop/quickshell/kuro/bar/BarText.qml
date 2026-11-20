// Plain text in the bar (clock, date).

import QtQuick
import qs.config

Text {
    leftPadding: 6
    rightPadding: 6
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize - 1
    font.letterSpacing: 0.5
}
