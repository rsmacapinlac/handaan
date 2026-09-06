// Quickshell desktop shell.
//
// Commons and Ui are reached as `qs.Commons` / `qs.Ui`, declared by a qmldir in
// each directory. That matters: a singleton imported by relative path is
// instantiated once per importing file, so every consumer silently gets its
// own empty copy. Only a type in a declared module is process-wide.

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
            // Leads the right section: it is absent most of the time, so
            // anything after it would shift sideways whenever it appeared.
            // Placed first, the widgets that are always there keep their
            // position and only the bar's leading edge moves.
            Component {
                Modules.Pending {}
            },
            Component {
                Modules.Battery {}
            },
            Component {
                Modules.Clock {}
            }
        ]
    }
}
