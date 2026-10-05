// Which summoned list is up: the one slot the installer and the wallpaper
// picker share, so that only one of them is ever open.
//
// Both are lists you summon to choose from, each holding the keyboard
// exclusively while it is up. Two at once would stack, with only the top one
// able to take a keystroke. So instead of each surface knowing to close the
// others -- a pair of calls for two surfaces, and a set that grows with every
// one added -- each derives its open state from this slot. Claiming the slot
// for one name is what closes whichever held it.
//
// Joining is opt-in. The power menu stays outside on purpose: it is reached
// when something is wrong, and must come up over whatever is open rather than
// replace it.
//
// Holds no IPC target. The surfaces are still reached through their own
// singletons' targets, which call claim and release here.

pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // The name holding the slot, or "" when nothing is up. Names in use:
    // "installer" (AppCatalog), "wallpapers" (Wallpapers).
    property string current: ""

    function claim(name) {
        root.current = name;
    }

    // Only the holder can empty the slot, so a close that arrives late cannot
    // put away a surface that has since taken it.
    function release(name) {
        if (root.current === name)
            root.current = "";
    }
}
