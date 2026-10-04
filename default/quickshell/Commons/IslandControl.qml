// The door the keyboard uses into the island, which Super+Shift+N reaches
// through bin/handaan-island.
//
// A singleton because the island cannot carry the IPC target itself: there is
// one per monitor, and a target name has to be unique in the process. This
// holds no state of its own -- whether an island is open stays on that island,
// since expansion is local to the monitor -- and only relays the request. Each
// island hears it and the one on the focused monitor acts, so the shortcut
// opens the island where you are working, the way a click opens the one you
// clicked.
//
// Named apart from Ui/Island.qml on purpose: a type sharing a name with a
// singleton imported into it shadows that singleton silently.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // "toggle", "open" or "close".
    signal requested(string action)

    IpcHandler {
        target: "island"

        // What Super+Shift+N calls, so a second press puts the island away the
        // way a second click on the cut-out does.
        function toggle(): string {
            root.requested("toggle");
            return "toggled";
        }

        function open(): string {
            root.requested("open");
            return "opened";
        }

        function close(): string {
            root.requested("close");
            return "closed";
        }
    }
}
