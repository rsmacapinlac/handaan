// Ending or pausing the session: lock, suspend, log out, restart, shut down.
//
// A singleton for the reason AppCatalog is one: the surface that draws the
// menu, Ui/PowerMenu.qml, is loaded on demand, and a thing that is not loaded
// cannot receive the IPC call asking it to appear. This is always resident,
// holds whether the menu is up, and carries the `sessionControl` target that
// Ctrl+Alt+Delete reaches through bin/handaan-session.
//
// It must be reached as `qs.Commons.SessionControl`, never by relative path --
// a pragma Singleton imported by path is instantiated once per importing file.
// The surface is named differently on purpose: a type sharing a name with a
// singleton imported into it shadows that singleton silently.
//
// The actions are the commands the rofi script this replaces ran, with one
// change. Lock goes through `loginctl lock-session` rather than exec'ing
// hyprlock, so it takes hypridle's `pidof hyprlock || hyprlock` guard -- the
// same path idle and suspend already lock through -- instead of starting a
// second hyprlock over one that is already up.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool menuOpen: false

    // `confirm` marks what cannot be undone from where you are sitting: each
    // of those ends every open window. Lock and suspend give the session back
    // intact, so asking twice would only slow down the common case.
    //
    // `keywords` are what typing in the menu also matches, so the word you
    // reach for finds the action whichever name it goes by here.
    readonly property var actions: [
        { id: "poweroff", label: "Shut down", icon: "󰐥", confirm: true,  keywords: "shutdown power off poweroff", command: ["systemctl", "poweroff"] },
        { id: "suspend",  label: "Suspend",   icon: "󰤄", confirm: false, keywords: "sleep",                       command: ["systemctl", "suspend"] },
        { id: "logout",   label: "Log out",   icon: "󰗽", confirm: true,  keywords: "logout sign out exit",        command: ["hyprctl", "dispatch", "exit"] },
        { id: "reboot",   label: "Restart",   icon: "󰜉", confirm: true,  keywords: "reboot",                      command: ["systemctl", "reboot"] },
        { id: "lock",     label: "Lock",      icon: "󰌾", confirm: false, keywords: "lock screen",                 command: ["loginctl", "lock-session"] }
    ]

    function open() {
        root.menuOpen = true;
    }

    function close() {
        root.menuOpen = false;
    }

    function toggle() {
        root.menuOpen = !root.menuOpen;
    }

    // Closes before running. Lock and suspend put something over the screen,
    // and a menu still mapped underneath it would be waiting there on return.
    function run(actionId) {
        for (var i = 0; i < root.actions.length; i++) {
            if (root.actions[i].id === actionId) {
                root.close();
                Quickshell.execDetached(root.actions[i].command);
                return;
            }
        }
    }

    IpcHandler {
        target: "sessionControl"

        // Toggle is what the keybind calls, so pressing Ctrl+Alt+Delete a
        // second time puts the menu away the way it brought it up.
        function toggle(): string {
            root.toggle();
            return root.menuOpen ? "opened" : "closed";
        }

        function open(): string {
            root.open();
            return "opened";
        }

        function close(): string {
            root.close();
            return "closed";
        }
    }
}
