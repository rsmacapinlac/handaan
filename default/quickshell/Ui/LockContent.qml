// What the lock screen draws on each monitor.
//
// Two questions, per docs/quickshell-widgets.md, read as a surface rather than
// a bar widget:
//   1. What does it take to get back in?
//   2. Is anything going to make my password fail?
//
// The first is answered by a password field and nothing else. The second has
// the only two strong states on the screen: the last attempt failed (critical,
// with PAM's reason where it gave one) and Caps Lock is on (warning). Both can
// be true at once and both are shown, because the second is usually why the
// first happened. Everything else recedes.
//
// The time and date are the one thing kept that is not about unlocking. The
// lock covers the bar, and its clock is the answer you still walk up to a
// locked screen wanting. They are drawn the way the bar's clock draws them --
// the time at full contrast, the date muted -- only larger.
//
// Deliberately left out: the avatar and the user name, which on a single-user
// machine answer nothing; a spinner while PAM checks, because sustained motion
// is reserved for "this needs a response" and a check that takes a second is
// not that; and any count of failed attempts beyond PAM's own words, since the
// number changes nothing you do next.
//
// A failed attempt shakes the field once. That is a transition, not motion: it
// is caused by the attempt, bounded, and over before you look back, and the
// failure is also carried by colour and words.
//
// The background is the current wallpaper, blurred, over an opaque colour that
// is all you see when there is no wallpaper or while it loads. Blurred rather
// than merely dimmed because some wallpapers are monthly calendars: sharp, their
// own dates and numbers would sit right behind the clock and the field, and
// compete with both. Blurred, it is still recognisably your wallpaper.

import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons

Item {
    id: root

    readonly property int timeSize: 88
    readonly property int dateSize: Style.fontSize + 5
    readonly property int fieldWidth: 340
    readonly property int fieldHeight: 52
    readonly property int dotSize: 10
    // More dots than this would outgrow the field; past it the row stops
    // growing, which is still enough to see that a key landed.
    readonly property int maxDots: 24

    readonly property bool failed: SessionLock.failure !== ""

    focus: true
    Component.onCompleted: root.forceActiveFocus()

    Keys.onPressed: event => {
        event.accepted = true;
        const control = (event.modifiers & Qt.ControlModifier) !== 0;
        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            SessionLock.submit();
            return;
        case Qt.Key_Backspace:
            if (control)
                SessionLock.clear();
            else
                SessionLock.erase();
            return;
        case Qt.Key_Escape:
            // In a preview, Escape on an empty field is the way out; with
            // something typed it clears first, as it does on a real lock.
            if (SessionLock.previewing && SessionLock.buffer === "")
                SessionLock.closePreview();
            else
                SessionLock.clear();
            return;
        case Qt.Key_CapsLock:
            SessionLock.checkCapsLock();
            return;
        case Qt.Key_U:
            if (control) {
                SessionLock.clear();
                return;
            }
            break;
        }
        if (control || event.text.length === 0 || event.text.charCodeAt(0) < 0x20)
            return;
        SessionLock.type(event.text);
    }

    // The Caps Lock state the compositor reports can trail the press, so ask
    // again once the key is back up.
    Keys.onReleased: event => {
        if (event.key === Qt.Key_CapsLock)
            SessionLock.checkCapsLock();
    }

    // ----------------------------------------------------------- background

    Rectangle {
        anchors.fill: parent
        color: Theme.lockBackground
    }

    Image {
        id: wallpaper

        anchors.fill: parent
        source: SessionLock.wallpaper ? "file://" + SessionLock.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.width
        sourceSize.height: root.height
        asynchronous: true
        cache: false
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        autoPaddingEnabled: false
    }

    Rectangle {
        anchors.fill: parent
        visible: wallpaper.status === Image.Ready
        color: Theme.lockScrim
    }

    // --------------------------------------------------------------- content

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.centerIn: parent
        spacing: Style.space(2)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.barText
            font.family: Style.fontFamily
            font.pixelSize: root.timeSize
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
            color: Theme.barTextMuted
            font.family: Style.fontFamily
            font.pixelSize: root.dateSize
        }

        Item {
            width: 1
            height: Style.space(10)
        }

        Rectangle {
            id: field

            anchors.horizontalCenter: parent.horizontalCenter
            width: root.fieldWidth
            height: root.fieldHeight
            radius: height / 2
            color: Theme.surface
            border.width: Style.borderWidth * 2
            border.color: {
                if (root.failed)
                    return Theme.critical;
                if (SessionLock.capsLock)
                    return Theme.warning;
                return Theme.border;
            }

            Behavior on border.color {
                ColorAnimation { duration: Style.animationFast }
            }

            transform: Translate {
                id: shake
            }

            Text {
                anchors.centerIn: parent
                visible: SessionLock.buffer.length === 0 && !SessionLock.checking
                text: "Password"
                color: Theme.barTextMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize + 2
            }

            Row {
                anchors.centerIn: parent
                spacing: Style.space(2)

                Repeater {
                    model: Math.min(SessionLock.buffer.length, root.maxDots)

                    delegate: Rectangle {
                        width: root.dotSize
                        height: root.dotSize
                        radius: width / 2
                        color: Theme.barText
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: SessionLock.checking
                text: "Checking…"
                color: Theme.barTextMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize + 2
            }
        }

        // Fixed height, so a message appearing never moves the field.
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            height: (Style.fontSize + Style.space(3)) * 2
            spacing: Style.space(1)
            topPadding: Style.space(2)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.failed
                text: SessionLock.failure
                color: Theme.critical
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: SessionLock.capsLock
                text: "󰪛  Caps Lock is on"
                color: Theme.warning
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
                font.bold: true
            }
        }
    }

    SequentialAnimation {
        id: shakeAnimation

        NumberAnimation { target: shake; property: "x"; to: -12; duration: 40 }
        NumberAnimation { target: shake; property: "x"; to: 12; duration: 60 }
        NumberAnimation { target: shake; property: "x"; to: -6; duration: 50 }
        NumberAnimation { target: shake; property: "x"; to: 0; duration: 50 }
    }

    Connections {
        target: SessionLock

        function onFailuresChanged() {
            shakeAnimation.restart();
        }

        function onShowingChanged() {
            if (SessionLock.showing)
                root.forceActiveFocus();
        }
    }
}
