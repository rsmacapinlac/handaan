// One notification, drawn the same way as a popup and in the history panel.
//
// A view onto a record from qs.Commons.NotificationCenter. It holds no state
// of its own beyond whether the pointer is on it, and says what was clicked
// through signals, so the popup can mean "take this off the screen" by close
// and the history can mean "dismiss it for good" by the same button.
//
// What it shows is the order you read a notification in: who sent it and when,
// what it says, what you can do about it. Critical is the one state drawn
// loudly, as a critical border, because it is the one that stays until you act.
//
// The body is the protocol's small markup subset -- bold, italic, underline --
// with images stripped. An <img> in a body can name a remote URL, and fetching
// it would tell a sender the notification was displayed.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons

Rectangle {
    id: root

    required property var record
    property int bodyLines: 4

    readonly property bool hovered: hover.hovered

    signal activated
    signal closeClicked
    signal actionClicked(string identifier)

    implicitHeight: layout.implicitHeight + Style.space(6)
    radius: Style.radius
    color: Theme.dialogSurface
    border.width: Style.borderWidth
    border.color: root.record.urgency === "critical" ? Theme.critical : Theme.border

    // An image the sender attached wins over its app icon: it is usually the
    // more specific thing -- the contact, the album -- and the app is named in
    // the header anyway. A bare name is looked up in the icon theme.
    readonly property string iconSource: {
        const candidates = [root.record.image, root.record.appIcon];
        for (var i = 0; i < candidates.length; i++) {
            const value = candidates[i] || "";
            if (value === "")
                continue;
            if (value.startsWith("/"))
                return "file://" + value;
            if (value.indexOf("://") !== -1)
                return value;
            const themed = Quickshell.iconPath(value, true);
            if (themed !== "")
                return themed;
        }
        return "";
    }

    readonly property var buttons: root.record.actions.filter(a => a.identifier !== "default" && a.text !== "")

    function age(time) {
        const seconds = Math.max(0, (NotificationCenter.now - time) / 1000);
        if (seconds < 60)
            return "now";
        if (seconds < 3600)
            return Math.floor(seconds / 60) + "m";
        if (seconds < 86400)
            return Math.floor(seconds / 3600) + "h";
        return Qt.formatDate(new Date(time), "d MMM");
    }

    HoverHandler {
        id: hover
    }

    // Left runs the sender's default action, if it has one; right puts the
    // card away. Neither destroys anything a click by accident could regret:
    // the popup's close keeps the notification in history.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.closeClicked();
            else
                root.activated();
        }
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Style.space(3)
        spacing: Style.space(3)

        Image {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            visible: root.iconSource !== "" && status !== Image.Error
            source: root.iconSource
            sourceSize.width: 72
            sourceSize.height: 72
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(1)

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.space(2)

                Text {
                    Layout.fillWidth: true
                    text: root.record.appName || "Notification"
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    color: Theme.barTextMuted
                }

                Text {
                    text: root.age(root.record.time)
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    color: Theme.barTextMuted
                }

                Text {
                    // Nerd Font U+F00D, "times". Escaped so the glyph survives edits.
                    text: "\uf00d"
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    color: close.containsMouse ? Theme.barText : Theme.barTextMuted

                    MouseArea {
                        id: close
                        anchors.fill: parent
                        anchors.margins: -Style.space(1.5)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeClicked()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.record.summary
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.PlainText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
                font.bold: true
                color: Theme.barText
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: (root.record.body || "").replace(/<img[^>]*>/gi, "")
                wrapMode: Text.Wrap
                maximumLineCount: root.bodyLines
                elide: Text.ElideRight
                textFormat: Text.StyledText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Theme.barText
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Style.space(1)
                visible: root.buttons.length > 0
                spacing: Style.space(1.5)

                Repeater {
                    model: root.buttons

                    delegate: Rectangle {
                        id: button

                        required property var modelData

                        implicitWidth: label.implicitWidth + Style.space(5)
                        implicitHeight: label.implicitHeight + Style.space(2)
                        radius: Style.radius
                        color: press.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.width: Style.borderWidth
                        border.color: Theme.border

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: button.modelData.text
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeSmall
                            color: Theme.barText
                        }

                        MouseArea {
                            id: press
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.actionClicked(button.modelData.identifier)
                        }
                    }
                }
            }
        }
    }
}
