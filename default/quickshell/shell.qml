// Quickshell desktop shell.
//
// Commons and Ui are reached as `qs.Commons` / `qs.Ui`, declared by a qmldir in
// each directory. That matters: a singleton imported by relative path is
// instantiated once per importing file, so every consumer silently gets its
// own empty copy. Only a type in a declared module is process-wide.

// The installer and the power menu are the shell's other surfaces: dialogs
// rather than bars, up only while summoned. They live here so they inherit
// Theme -- see Ui/Installer.qml with Commons/AppCatalog.qml, and Ui/PowerMenu.qml
// with Commons/SessionControl.qml. The lock screen is the same arrangement:
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
            // Optional indicators lead the right section, keeping Battery
            // and Clock in place when either indicator appears or disappears.
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

    LockScreen {}
}
