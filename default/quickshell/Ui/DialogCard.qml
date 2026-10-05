// The card a summoned list is drawn on: the installer's and the wallpaper
// picker's.
//
// Framed the way the rofi launcher's window is -- a heavy accent border and a
// softer corner -- so every list you summon to choose from reads as one family.
// It is a component rather than four properties each dialog sets, because
// copying the values is how the two drifted apart in the first place: the
// installer took the rofi frame and the picker kept a thin grey line. A dialog
// sets only its size and what goes inside.
//
// The power menu and the notification history are not summoned lists and keep
// their own, quieter frame.
//
// It also swallows clicks, so the click-anywhere-to-dismiss handler behind it
// does not fire when the pointer lands on the card itself. Pointer movement
// over the card is passed on as pointerMoved, for a dialog that arms pointer
// selection only once the pointer has actually moved.

import QtQuick
import qs.Commons

Rectangle {
    id: root

    signal pointerMoved

    color: Theme.dialogSurface
    radius: Style.radius + 4
    border.width: 4
    border.color: Theme.active

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: root.pointerMoved()
    }
}
