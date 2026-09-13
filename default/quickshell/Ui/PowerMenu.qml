// The session menu: shut down, suspend, log out, restart, lock.
//
// A view onto qs.Commons.SessionControl, which owns the open state and the
// commands. It replaces a rofi script that wrote a theme file into
// ~/.config/rofi on every run and carried its own hand-copied Mocha, so
// regenerating the palette never reached it. Here every colour is a Theme role.
//
// One surface on the focused monitor, like the installer, and for the same
// reason: there is one menu and it belongs where you are looking.
//
// A compact card: a filter field, the actions in a single row, and a status
// line. Typing narrows the row, the arrows move along it, Enter acts
// and Esc leaves. It stays quiet -- no scrim, a plain border, a soft highlight
// under the cursor -- because the one thing here that needs to be loud is the
// confirmation, and it only gets to be loud if nothing else is.
//
// The field, the highlight and the armed state are drawn exactly as the
// installer draws them, so the shell's two dialogs read as one vocabulary.
//
// Log out, restart and shut down ask twice: the item turns warning and the
// status line says what a second Enter will do, because each ends every open
// window. Lock and suspend act at once. That is the installer's rule applied
// again -- confirm only where one keypress too many costs something you cannot
// get back.

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
    visible: SessionControl.menuOpen

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
    WlrLayershell.namespace: "handaan-power-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // One column per action, so the whole menu reads as a single row. Taken
    // from the full list rather than the filtered one: a filter that leaves
    // two actions should not stretch them across the card.
    readonly property int columns: SessionControl.actions.length

    // Every cell is as wide as the longest label needs, measured from the text
    // itself rather than from the laid-out cells -- sizing the card from the
    // cells inside it is the polish loop the grid below exists to avoid. The
    // shell font is monospaced, so the longest label by length is the widest.
    readonly property int labelSize: Style.fontSize + 1
    readonly property int iconSize: Style.fontSize + 2
    readonly property string longestLabel: {
        var longest = "";
        const actions = SessionControl.actions;
        for (var i = 0; i < actions.length; i++) {
            if (actions[i].label.length > longest.length)
                longest = actions[i].label;
        }
        return longest;
    }
    readonly property real cellWidth: Math.ceil(labelMetrics.advanceWidth + root.iconSize + Style.space(1.5) + Style.space(8))

    TextMetrics {
        id: labelMetrics

        text: root.longestLabel
        font.family: Style.fontFamily
        font.pixelSize: root.labelSize
        font.bold: true
    }

    // The actions left after filtering, in SessionControl's order.
    property var items: []
    property int cursor: 0

    // The id of the item waiting for its second Enter, or "". Cleared by any
    // movement or keystroke, so an armed item can never be left behind the
    // cursor.
    property string armed: ""

    // Set by the first real pointer movement. The menu opens under wherever
    // the pointer already was, and without this that stale position would
    // steal the cursor from the keyboard; see Ui/Installer.qml.
    property bool pointerArmed: false

    readonly property var armedAction: {
        for (var i = 0; i < root.items.length; i++) {
            if (root.items[i].id === root.armed)
                return root.items[i];
        }
        return null;
    }

    function rebuildItems() {
        const query = search.text.toLowerCase().trim();
        const actions = SessionControl.actions;
        var next = [];
        for (var i = 0; i < actions.length; i++) {
            const haystack = (actions[i].label + " " + actions[i].keywords).toLowerCase();
            if (query.length === 0 || haystack.indexOf(query) !== -1)
                next.push(actions[i]);
        }
        root.items = next;
        root.armed = "";
        root.cursor = next.length > 0 ? 0 : -1;
    }

    // Wraps, because a row this short is faster to leave by the near end
    // than to walk back along.
    function moveCursor(delta) {
        const count = root.items.length;
        if (count === 0)
            return;
        root.armed = "";
        root.cursor = (root.cursor + delta + count) % count;
    }

    function activate() {
        if (root.cursor < 0 || root.cursor >= root.items.length)
            return;
        const action = root.items[root.cursor];
        if (action.confirm && root.armed !== action.id) {
            root.armed = action.id;
            return;
        }
        SessionControl.run(action.id);
    }

    function dismiss() {
        if (root.armed !== "") {
            root.armed = "";
            return;
        }
        SessionControl.close();
    }

    onVisibleChanged: {
        if (visible) {
            search.text = "";
            root.pointerArmed = false;
            root.rebuildItems();
            search.forceActiveFocus();
        }
    }

    // Click outside the card to dismiss. Always safe: nothing runs until an
    // item is chosen.
    MouseArea {
        anchors.fill: parent
        onClicked: SessionControl.close()
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(root.cellWidth * root.columns + Style.space(1) * (root.columns - 1) + Style.space(6),
                        parent.width - Style.space(8))
        height: layout.implicitHeight + Style.space(6)

        color: Theme.dialogSurface
        radius: Style.radius
        border.width: Style.borderWidth
        border.color: Theme.border

        // Swallows clicks so the dismiss handler behind the card does not fire.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: root.pointerArmed = true
        }

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: Style.space(3)
            spacing: Style.space(2)

            // ------------------------------------------------------- filter
            //
            // Styled exactly as the installer's search field, so the shell's
            // dialogs share one text box rather than each drawing its own.
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: search.implicitHeight + Style.space(3)
                radius: Style.radius
                color: Theme.surface
                border.width: Style.borderWidth
                border.color: search.activeFocus ? Theme.active : Theme.border

                TextInput {
                    id: search

                    anchors.fill: parent
                    anchors.leftMargin: Style.space(3)
                    anchors.rightMargin: Style.space(3)
                    verticalAlignment: TextInput.AlignVCenter

                    focus: true
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSize
                    color: Theme.barText
                    selectionColor: Theme.active
                    selectedTextColor: Theme.barBackground
                    clip: true

                    onTextChanged: root.rebuildItems()

                    // Every arrow drives the grid rather than the caret.
                    // A filter this short is retyped, not edited.
                    Keys.onLeftPressed: root.moveCursor(-1)
                    Keys.onRightPressed: root.moveCursor(1)
                    Keys.onTabPressed: root.moveCursor(1)
                    Keys.onBacktabPressed: root.moveCursor(-1)
                    Keys.onReturnPressed: root.activate()
                    Keys.onEnterPressed: root.activate()
                    Keys.onEscapePressed: root.dismiss()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text.length === 0
                        text: "Search power options"
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSize
                        color: Theme.barTextMuted
                    }
                }
            }

            // --------------------------------------------------------- grid
            //
            // A GridLayout rather than a Grid positioner. A Grid sized by the
            // ColumnLayout around it, with cells sized from the Grid's width,
            // is a loop: the layout reads the Grid's implicit width from its
            // cells, the cells read the Grid's width, and the Grid re-polishes
            // forever without drawing a cell. Here the layout owns the widths
            // and uniformCellWidths splits them evenly.
            GridLayout {
                id: grid

                Layout.fillWidth: true
                visible: root.items.length > 0
                columns: root.columns
                columnSpacing: Style.space(1)
                rowSpacing: Style.space(1)
                uniformCellWidths: true

                Repeater {
                    model: root.items

                    delegate: Rectangle {
                        id: item

                        required property int index
                        required property var modelData

                        readonly property bool current: root.cursor === item.index
                        readonly property bool arming: root.armed === item.modelData.id

                        // A nominal preferred width, so the label's own width
                        // never argues with the even split.
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: label.implicitHeight + Style.space(6)
                        radius: Style.radius

                        color: {
                            if (item.arming)
                                return Theme.warning;
                            if (item.current)
                                return Theme.surfaceHover;
                            return "transparent";
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onPositionChanged: {
                                root.pointerArmed = true;
                                if (root.cursor !== item.index) {
                                    root.armed = "";
                                    root.cursor = item.index;
                                }
                            }
                            onEntered: {
                                if (root.pointerArmed && root.cursor !== item.index) {
                                    root.armed = "";
                                    root.cursor = item.index;
                                }
                            }
                            onClicked: {
                                root.cursor = item.index;
                                root.activate();
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: Style.space(1.5)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: item.modelData.icon
                                font.family: Style.fontFamily
                                font.pixelSize: root.iconSize
                                color: item.arming ? Theme.barBackground : Theme.barText
                            }

                            Text {
                                id: label

                                anchors.verticalCenter: parent.verticalCenter
                                text: item.modelData.label
                                font.family: Style.fontFamily
                                font.pixelSize: root.labelSize
                                font.bold: item.current
                                color: item.arming ? Theme.barBackground : Theme.barText
                            }
                        }
                    }
                }
            }

            // -------------------------------------------------------- status
            //
            // Carries the confirmation prompt when an item is armed -- an
            // item's own cell is too narrow to say it -- and otherwise the
            // keys, or why the grid is empty. Plain text on the card: with no
            // pill behind it, the prompt is marked by colour alone, which is
            // still enough beside an item that has already turned warning.
            Text {
                id: status

                Layout.fillWidth: true
                Layout.topMargin: Style.space(1)
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                font.bold: root.armedAction !== null
                color: root.armedAction ? Theme.warning : Theme.barTextMuted
                text: {
                    if (root.armedAction)
                        return "Enter or click again to " + root.armedAction.label.toLowerCase() + " · Esc to cancel";
                    if (root.items.length === 0)
                        return "Nothing matches \"" + search.text + "\"";
                    return "Type to filter · arrows move · Enter choose · Esc close";
                }
            }
        }
    }
}
