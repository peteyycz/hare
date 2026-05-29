import QtQuick
import Quickshell

ShellRoot {
    // Realize the notification singleton at startup so the freedesktop server
    // registers immediately (not lazily on first panel open).
    Component.onCompleted: Notifs.list

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
