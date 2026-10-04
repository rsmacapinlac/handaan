// Quickshell desktop shell.
//
// Commons and Ui are reached as `qs.Commons` / `qs.Ui`, declared by a qmldir in
// each directory. That matters: a singleton imported by relative path is
// instantiated once per importing file, so every consumer silently gets its
// own empty copy. Only a type in a declared module is process-wide.

// The installer, the power menu and the wallpaper picker are the shell's other surfaces: dialogs
// rather than bars, up only while summoned. They live here so they inherit
// Theme -- see Ui/Installer.qml with Commons/AppCatalog.qml, and Ui/PowerMenu.qml
// with Commons/SessionControl.qml, and Ui/WallpaperPicker.qml with
// Commons/Wallpapers.qml. Notifications are Ui/NotificationPopups.qml and
// Ui/NotificationHistory.qml over Commons/NotificationCenter.qml, which is also
// the session's notification daemon. The lock screen is the same arrangement:
// Ui/LockScreen.qml with Commons/SessionLock.qml.

import QtQuick
import Quickshell
import qs.Ui
import "modules" as Modules

ShellRoot {
    Bar {
        position: "top"

        leftWidgets: [
            Component {
                Modules.Workspaces {}
            }
        ]

        rightWidgets: [
            // Network and Battery sit together as the state of the machine,
            // then the Clock at the end. Updates comes and goes; the row is
            // anchored right, so its arriving shifts what is to its left and
            // the Clock never moves.
            //
            // The Bell used to sit between Battery and Clock. It is the
            // island's now -- what is waiting is a backlog rather than the
            // state of this machine, and the island is where notifications
            // are. See docs/island/README.md.
            Component {
                Modules.Updates {}
            },
            Component {
                Modules.Network {}
            },
            Component {
                Modules.Battery {}
            },
            Component {
                Modules.Clock {}
            }
        ]
    }

    Installer {}

    PowerMenu {}

    WallpaperPicker {}

    NotificationPopups {}

    NotificationHistory {}

    LockScreen {}
}
