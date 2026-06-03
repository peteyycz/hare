import QtQuick
import Quickshell

ShellRoot {
    // Realize a couple of singletons eagerly so their startup work happens
    // before the user can interact with them: the notification server has to
    // register on the bus (not lazily on first panel open), and PowerProfiles
    // needs its `command -v powerprofilesctl` probe to finish before the
    // Battery button can decide whether to open its popup.
    Component.onCompleted: {
        Notifs.list;
        PowerProfilesCtl.available;
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    // Transient toasts live on the primary screen only.
    NotifToasts {
        screen: Quickshell.screens[0] ?? null
    }

    // Volume OSD — flashes on the primary screen when the volume changes.
    VolumeOsd {
        screen: Quickshell.screens[0] ?? null
    }
}
