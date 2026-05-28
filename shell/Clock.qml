import QtQuick
import Quickshell

Text {
    id: root

    text: Qt.formatDateTime(clock.date, "ddd  HH:mm")
    color: Theme.fg
    font.family: Theme.fonts.sans
    font.pixelSize: 13
    font.weight: Font.Medium

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
