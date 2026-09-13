// The lock screen, and its preview.
//
// A view onto qs.Commons.SessionLock, which owns whether the session is locked
// and decides when it may unlock. What each monitor shows is Ui/LockContent.qml;
// this file only decides what it is drawn on.
//
// Locked, it is drawn on ext-session-lock-v1 surfaces. That protocol is what
// makes it a lock rather than a window over the desktop: the compositor stops
// drawing everything else and sends every key here, and if this process dies
// the session stays locked instead of falling open. SessionLock's marker is
// what brings the lock back when the shell restarts.
//
// Previewing, the same content is drawn on overlay layer surfaces, one per
// monitor, which lock nothing and close with Escape.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

Scope {
    id: root

    WlSessionLock {
        id: lock

        locked: SessionLock.locked

        // Going unlocked while SessionLock still says locked means the
        // compositor refused or ended the lock, not that PAM let anyone in.
        onLockedChanged: {
            if (!lock.locked && SessionLock.locked)
                SessionLock.lockLost();
        }

        WlSessionLockSurface {
            color: Theme.lockBackground

            LockContent {
                anchors.fill: parent
            }
        }
    }

    Variants {
        model: SessionLock.previewing ? Quickshell.screens : []

        delegate: PanelWindow {
            id: preview

            required property var modelData

            screen: preview.modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.lockBackground

            WlrLayershell.namespace: "handaan-lock-preview"
            WlrLayershell.layer: WlrLayer.Overlay
            // Only the focused monitor takes the keyboard. Every monitor shows
            // the same state, so it does not matter which one you type at, but
            // several surfaces each demanding exclusive focus is a fight.
            WlrLayershell.keyboardFocus: Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === preview.modelData.name
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            LockContent {
                anchors.fill: parent
            }
        }
    }
}
