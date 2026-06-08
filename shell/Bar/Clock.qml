import QtQuick
import QtQuick.Layouts
import Quickshell
import "../Theme"

// Centered clock: time (bold) + date (dim).
RowLayout {
    id: root
    spacing: 9

    Text {
        Layout.alignment: Qt.AlignBaseline
        text: Qt.formatDateTime(clock.date, "HH:mm")
        font.family: Theme.fonts.sans
        font.pixelSize: 14
        font.weight: Font.DemiBold
        color: Theme.text
    }

    Text {
        Layout.alignment: Qt.AlignBaseline
        text: Qt.formatDateTime(clock.date, "ddd d MMM")
        font.family: Theme.fonts.sans
        font.pixelSize: 13
        color: Theme.textDim
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
