import QtQuick
import Quickshell
import "Services"
import "Bar"
import "Panels/Notifications"
import "Panels/Volume"

ShellRoot {
    // Realize a couple of singletons eagerly so their startup work happens
    // before the user can interact with them: the notification server has to
    // register on the bus (not lazily on first panel open), and PowerProfiles
    // needs its `command -v powerprofilesctl` probe to finish before the
    // BatteryButton can decide whether to open its popup.
    Component.onCompleted: {
        NotificationService.list;
        PowerProfileService.available;
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    // Transient toasts live on the primary screen only.
    NotificationToasts {
        screen: Quickshell.screens[0] ?? null
    }

    // Volume OSD — flashes on the primary screen when the volume changes.
    VolumeOsd {
        screen: Quickshell.screens[0] ?? null
    }
}
