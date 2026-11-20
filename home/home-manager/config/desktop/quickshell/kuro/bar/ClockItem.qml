// Clock in the bar: left-click opens the calendar.
//   wheel                    : handled by BarItem (time/date scrolling)

import QtQuick
import qs.config

BarItem {
    id: root

    required property var barWindow
    property string format: "hh:mm"

    // pinned keeps the calendar open until it is clicked again or focus leaves it
    property bool pinned: false

    label: Qt.formatDateTime(BarState.clock.date, format)

    function openCal()  { calendar.open = true; }
    function closeCal() { calendar.open = false; pinned = false; }
    function toggleCalendar() {
        if (calendar.open) closeCal();
        else { pinned = true; openCal(); }
    }

    CalendarPopup {
        id: calendar
        barWindow: root.barWindow
        target: root
        open: false

        onDismissed: {
            pinned = false;
            calendar.open = false;
        }
    }

}
