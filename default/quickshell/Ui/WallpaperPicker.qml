// The wallpaper picker: see the wallpapers, choose one.
//
// A view onto qs.Commons.Wallpapers, which owns the list, the open state and
// how a choice is applied. Choosing is the only way handaan's colours change --
// there is no theme to pick, because the palette is taken from the wallpaper.
//
// One surface on the focused monitor, like the installer and the power menu,
// and drawn with their field, highlight and status line so the shell's dialogs
// read as one vocabulary.
//
// A grid of thumbnails, because what is being chosen is a picture. Random is the
// first cell, so Super+Shift+W then Enter is the old "give me another" key.
// Typing narrows by filename, the arrows move in two dimensions, Enter sets
// and Esc leaves. Nothing asks twice: a wallpaper you did not want is one more
// choice away, and the picker opens on the one you had.
//
// Under the grid sit the name of the one under the cursor and its credit, read
// from the .credit file beside the image -- see default/wallpapers/README.md.
//
// No scrim, unlike the installer: the wallpaper behind the card is what you are
// comparing the thumbnails against.

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
    visible: Wallpapers.pickerOpen

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
    WlrLayershell.namespace: "handaan-wallpaper-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    readonly property int columns: 4
    readonly property int visibleRows: 3
    readonly property int thumbWidth: 208
    readonly property int thumbHeight: Math.round(root.thumbWidth * 9 / 16)
    readonly property int cellPadding: Style.space(1.5)
    readonly property int cellWidth: root.thumbWidth + root.cellPadding * 2
    readonly property int cellHeight: root.thumbHeight + root.cellPadding * 2

    // { kind: "random" | "image", path, name, origin, credit }, Random first.
    property var items: []
    property int cursor: 0

    // Set by the first real pointer movement. The picker opens under wherever
    // the pointer already was, and without this that stale position would
    // steal the cursor from the keyboard; see Ui/Installer.qml.
    property bool pointerArmed: false

    readonly property var focused: root.cursor >= 0 && root.cursor < root.items.length ? root.items[root.cursor] : null

    // A path as a URL. Filenames carry brackets, quotes and worse, and a bare
    // "file://" + path turns a "#" or "?" into a fragment or a query.
    function fileUrl(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    function rebuildItems() {
        const query = search.text.toLowerCase().trim();
        var next = [];
        // Random only when there is something to choose between.
        if (Wallpapers.entries.length > 0 && (query.length === 0 || "random surprise shuffle".indexOf(query) !== -1))
            next.push({ kind: "random", path: "", name: "Random", origin: "", credit: null });

        const entries = Wallpapers.entries;
        var currentIndex = -1;
        for (var i = 0; i < entries.length; i++) {
            if (query.length > 0 && entries[i].name.toLowerCase().indexOf(query) === -1)
                continue;
            if (entries[i].path === Wallpapers.current)
                currentIndex = next.length;
            next.push({ kind: "image", path: entries[i].path, name: entries[i].name, origin: entries[i].origin, credit: entries[i].credit });
        }

        root.items = next;
        // Unfiltered, open on the wallpaper you have; filtered, on the best match.
        if (query.length === 0 && currentIndex !== -1)
            root.cursor = currentIndex;
        else
            root.cursor = next.length > 0 ? 0 : -1;
        grid.positionViewAtIndex(Math.max(root.cursor, 0), GridView.Contain);
    }

    // Left and right run on through the rows; up and down keep the column and
    // stop at the edges rather than wrapping into a different column.
    function moveCursor(delta, vertical) {
        const count = root.items.length;
        if (count === 0)
            return;
        var next = root.cursor + delta;
        if (vertical) {
            if (next < 0 || next >= count)
                return;
        } else {
            next = (next + count) % count;
        }
        root.cursor = next;
        grid.positionViewAtIndex(root.cursor, GridView.Contain);
    }

    function activate() {
        const item = root.focused;
        if (!item)
            return;
        if (item.kind === "random")
            Wallpapers.random();
        else
            Wallpapers.set(item.path);
    }

    onVisibleChanged: {
        if (visible) {
            search.text = "";
            root.pointerArmed = false;
            root.rebuildItems();
            search.forceActiveFocus();
        }
    }

    Connections {
        target: Wallpapers
        function onEntriesChanged() {
            if (root.visible)
                root.rebuildItems();
        }
    }

    // Click outside the card to dismiss. Always safe: nothing changes until a
    // wallpaper is chosen.
    MouseArea {
        anchors.fill: parent
        onClicked: Wallpapers.close()
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(root.cellWidth * root.columns + Style.space(6), parent.width - Style.space(8))
        height: Math.min(layout.implicitHeight + Style.space(6), parent.height - Style.space(8))

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
            // The installer's search field, drawn the same way.
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
                    Keys.onLeftPressed: root.moveCursor(-1, false)
                    Keys.onRightPressed: root.moveCursor(1, false)
                    Keys.onUpPressed: root.moveCursor(-root.columns, true)
                    Keys.onDownPressed: root.moveCursor(root.columns, true)
                    Keys.onTabPressed: root.moveCursor(1, false)
                    Keys.onBacktabPressed: root.moveCursor(-1, false)
                    Keys.onReturnPressed: root.activate()
                    Keys.onEnterPressed: root.activate()
                    Keys.onEscapePressed: Wallpapers.close()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text.length === 0
                        text: "Search wallpapers"
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSize
                        color: Theme.barTextMuted
                    }
                }
            }

            // --------------------------------------------------------- grid
            GridView {
                id: grid

                Layout.fillWidth: true
                Layout.preferredHeight: root.cellHeight * Math.min(root.visibleRows, Math.ceil(root.items.length / root.columns))
                visible: root.items.length > 0

                model: root.items
                cellWidth: Math.floor(width / root.columns)
                cellHeight: root.cellHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: cell

                    required property int index
                    required property var modelData

                    readonly property bool current: root.cursor === cell.index
                    readonly property bool onScreen: cell.modelData.kind === "image" && cell.modelData.path === Wallpapers.current

                    width: grid.cellWidth
                    height: grid.cellHeight

                    // The cursor is the accent frame; the wallpaper already up
                    // is a quiet outline. Two states, and only the cursor is loud.
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Style.space(0.5)
                        radius: Style.radius
                        color: cell.current ? Theme.active : "transparent"
                        border.width: cell.onScreen && !cell.current ? Style.borderWidth * 2 : 0
                        border.color: Theme.barTextMuted
                    }

                    Rectangle {
                        id: frame

                        anchors.fill: parent
                        anchors.margins: root.cellPadding
                        radius: Style.radius
                        color: Theme.surface
                        clip: true

                        Image {
                            anchors.fill: parent
                            visible: cell.modelData.kind === "image"
                            source: cell.modelData.kind === "image" ? root.fileUrl(cell.modelData.path) : ""
                            // Decoded at thumbnail size, not at 2560px: sixty
                            // full-size wallpapers would be gigabytes of texture.
                            sourceSize.width: root.thumbWidth * 2
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        Column {
                            anchors.centerIn: parent
                            visible: cell.modelData.kind === "random"
                            spacing: Style.space(1)

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "\udb81\udc9d"
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontSize * 2
                                color: Theme.barText
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Random"
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontSize
                                color: Theme.barText
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: {
                            root.pointerArmed = true;
                            root.cursor = cell.index;
                        }
                        onEntered: {
                            if (root.pointerArmed)
                                root.cursor = cell.index;
                        }
                        onClicked: {
                            root.cursor = cell.index;
                            root.activate();
                        }
                    }
                }
            }

            // -------------------------------------------------------- status
            //
            // The one under the cursor -- a thumbnail cannot say its own name,
            // or who made it -- or why the grid is empty.
            Text {
                Layout.fillWidth: true
                Layout.topMargin: Style.space(1)
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
                color: Wallpapers.error !== "" ? Theme.critical : Theme.barText
                text: {
                    if (Wallpapers.error !== "")
                        return Wallpapers.error + " -- run handaan-wallpaper-manifest to see why";
                    if (!Wallpapers.loaded)
                        return "Reading wallpapers...";
                    if (Wallpapers.entries.length === 0)
                        return "No wallpapers yet";
                    if (root.items.length === 0)
                        return "Nothing matches \"" + search.text + "\"";
                    const item = root.focused;
                    if (!item)
                        return "";
                    if (item.kind === "random")
                        return "Random";
                    const title = item.credit && item.credit.title ? item.credit.title : item.name;
                    var tags = [];
                    if (item.origin === "yours")
                        tags.push("yours");
                    if (item.path === Wallpapers.current)
                        tags.push("current");
                    return title + (tags.length > 0 ? "  (" + tags.join(", ") + ")" : "");
                }
            }

            // The credit, on its own line so a long title never pushes it out
            // of sight. Quiet: it is owed, not asked for.
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Theme.barTextMuted
                text: {
                    if (Wallpapers.loaded && Wallpapers.error === "" && Wallpapers.entries.length === 0)
                        return "Add images to ~/.config/handaan/wallpapers";
                    const item = root.focused;
                    if (!item || item.kind !== "image")
                        return "arrows move · Enter set · Esc close";
                    const credit = item.credit;
                    if (!credit || !credit.artist)
                        return "No credit recorded";
                    // The artist's own link stays in the .credit file; the
                    // line shows the name, cut at the first comma.
                    const artist = credit.artist.split(",")[0].trim();
                    return "by " + artist
                        + (credit.via ? " via " + credit.via.split(",")[0].trim() : "")
                        + (credit.license ? " · " + credit.license : "");
                }
            }
        }
    }
}
