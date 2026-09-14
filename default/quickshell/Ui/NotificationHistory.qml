// The notification history, and the do-not-disturb switch.
//
// A view onto qs.Commons.NotificationCenter. Summoned by Super+Shift+N, the
// bar's bell, or `handaan notifications`, and dismissed like the shell's other
// dialogs: Escape, or a click anywhere off the panel.
//
// A panel at the top right, under where the popups appear, so opening it reads
// as the popups staying put and the ones already gone coming back. On the
// focused monitor, for the reason the popups are.
//
// Every card here is the popup it once was, with its actions still live while
// the notification is kept. Closing a card here dismisses it for good, which is
// the difference from a popup's close: the popup was on its way to history, and
// this is history.
//
// Opening it is reading it -- NotificationCenter marks everything seen -- so
// there is no per-card "mark read" to manage. Reading is not dealing with,
// though: the bell stays until a card is closed here or the history cleared.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

PanelWindow {
    id: root

    // Unmapped when closed: the surface holds exclusive keyboard focus while
    // it is up. See Ui/Installer.qml.
    visible: NotificationCenter.historyOpen

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
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    WlrLayershell.namespace: "handaan-notification-history"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
        if (visible)
            keys.forceActiveFocus();
    }

    Item {
        id: keys

        focus: true
        Keys.onEscapePressed: NotificationCenter.closeHistory()
    }

    // Click outside the panel to dismiss. Always safe: nothing is lost.
    MouseArea {
        anchors.fill: parent
        onClicked: NotificationCenter.closeHistory()
    }

    Rectangle {
        id: panel

        anchors.top: parent.top
        anchors.right: parent.right
        // In line with the windows. The surface already starts below the bar,
        // since it respects the bar's exclusive zone; Hyprland's outer gap on
        // top and right puts the panel's border where a window's would be.
        anchors.topMargin: Style.windowGap
        anchors.rightMargin: Style.windowGap

        width: Math.min(420, parent.width - 2 * Style.windowGap)
        height: Math.min(layout.implicitHeight + Style.space(6), parent.height - 2 * Style.windowGap)

        color: Theme.dialogSurface
        radius: Style.radius
        border.width: Style.borderWidth
        border.color: Theme.border

        // Swallows clicks so the dismiss handler behind the panel does not fire.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: Style.space(3)
            spacing: Style.space(3)

            // ------------------------------------------------------- header
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.space(2)

                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSize
                    font.bold: true
                    color: Theme.barText
                }

                // Do-not-disturb is a state, so it is drawn as one: filled with
                // the accent while it is on, a plain outline while it is off.
                Rectangle {
                    implicitWidth: dndLabel.implicitWidth + Style.space(5)
                    implicitHeight: dndLabel.implicitHeight + Style.space(2)
                    radius: Style.radius
                    color: NotificationCenter.doNotDisturb ? Theme.active : (dnd.containsMouse ? Theme.surfaceHover : Theme.surface)
                    border.width: Style.borderWidth
                    border.color: NotificationCenter.doNotDisturb ? Theme.active : Theme.border

                    Text {
                        id: dndLabel
                        anchors.centerIn: parent
                        // Nerd Font U+F1F6 / U+F0F3: bell slash, bell.
                        text: (NotificationCenter.doNotDisturb ? "\uf1f6" : "\uf0f3") + "  Do not disturb"
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeSmall
                        color: NotificationCenter.doNotDisturb ? Theme.barBackground : Theme.barText
                    }

                    MouseArea {
                        id: dnd
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationCenter.setDoNotDisturb(!NotificationCenter.doNotDisturb)
                    }
                }

                Text {
                    visible: NotificationCenter.history.length > 0
                    text: "Clear all"
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    color: clear.containsMouse ? Theme.barText : Theme.barTextMuted

                    MouseArea {
                        id: clear
                        anchors.fill: parent
                        anchors.margins: -Style.space(1.5)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationCenter.clearAll()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: Style.space(2)
                visible: NotificationCenter.history.length === 0
                text: NotificationCenter.doNotDisturb
                      ? "Nothing here. Do not disturb is on: new notifications will wait here quietly."
                      : "Nothing here."
                wrapMode: Text.Wrap
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Theme.barTextMuted
            }

            // ---------------------------------------------------------- list
            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: contentHeight
                visible: NotificationCenter.history.length > 0

                model: NotificationCenter.history
                spacing: Style.space(2)
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: NotificationCard {
                    id: card

                    required property var modelData

                    width: list.width
                    record: card.modelData
                    bodyLines: 8

                    // Acting on a notification usually brings its app forward,
                    // and the panel would be in front of it.
                    onActivated: {
                        NotificationCenter.activate(card.modelData.id, "");
                        NotificationCenter.closeHistory();
                    }
                    onActionClicked: identifier => {
                        NotificationCenter.activate(card.modelData.id, identifier);
                        NotificationCenter.closeHistory();
                    }
                    onCloseClicked: NotificationCenter.dismiss(card.modelData.id)
                }
            }
        }
    }
}
