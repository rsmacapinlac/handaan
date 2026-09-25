// Notification popups: the top centre of the monitor you are looking at, under
// the island that has already said something arrived.
//
// `NotificationPopups` rather than `Notifications`, which would shadow
// Quickshell's own `Quickshell.Services.Notifications` in any file importing
// both -- the trap AGENTS.md records for `Palette`. It is also the word the
// rest of this reads in: NotificationCenter keeps `popups`, and the shell
// pops them up.
//
// A view onto qs.Commons.NotificationCenter's popups, which decides what is on
// screen and for how long -- an independent two-second countdown per popup.
// This only draws them.
//
// One surface, on the focused monitor, like the shell's dialogs: a notification
// belongs where you are looking, and with two screens a popup on the other one
// is a popup missed. Sized to its cards rather than to the screen, so the rest
// of the monitor stays clickable and nothing here takes the keyboard.
//
// Hidden while the history panel is up, which shows the same notifications and
// would otherwise sit on top of them, and while the session is locked.
//
// A card arriving slides in and one leaving fades: transitions, over before you
// look, and nothing loops. Motion on the desktop is rationed to "this needs a
// response" (docs/bar.md); kept notifications remain available in the island.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

PanelWindow {
    id: root

    visible: NotificationCenter.popups.length > 0 && !NotificationCenter.historyOpen && !SessionLock.locked

    // Matched by connector name; see Ui/Installer.qml.
    readonly property var focusedScreen: {
        const monitor = Hyprland.focusedMonitor;
        if (!monitor)
            return null;
        const screens = Quickshell.screens;
        for (var i = 0; i < screens.length; i++) {
            if (screens[i].name === monitor.name)
                return screens[i];
        }
        return null;
    }

    screen: root.focusedScreen

    anchors {
        top: true
    }

    // Under the island, in the centre, because that is where the island has
    // already said something arrived -- a popup on the far side of the screen
    // would be the same notification announced in two unrelated places.
    // Anchored top only, so the surface centres itself on the screen.
    //
    // In line with the windows: below the bar's exclusive zone, reserving none
    // of our own, and inset by Hyprland's outer gap so the cards' edges meet
    // the window borders' edges.
    exclusionMode: ExclusionMode.Normal
    margins {
        top: Style.windowGap
    }

    implicitWidth: 380
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"

    WlrLayershell.namespace: "handaan-notifications"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Column {
        id: stack

        width: parent.width
        // Hyprland's gap between windows, for the same reason.
        spacing: Style.windowGap

        add: Transition {
            NumberAnimation {
                property: "x"
                from: 40
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Style.animationNormal
            }
        }

        move: Transition {
            NumberAnimation {
                property: "y"
                duration: Style.animationFast
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: NotificationCenter.popups

            delegate: NotificationCard {
                id: card

                required property var modelData

                width: stack.width
                record: card.modelData.record
                bodyLines: 4

                onHoveredChanged: NotificationCenter.hold(card.modelData.id, card.hovered)
                Component.onDestruction: NotificationCenter.hold(card.modelData.id, false)

                onActivated: NotificationCenter.activate(card.modelData.id, "")
                onCloseClicked: NotificationCenter.hidePopup(card.modelData.id)
                onActionClicked: identifier => NotificationCenter.activate(card.modelData.id, identifier)
            }
        }
    }
}
