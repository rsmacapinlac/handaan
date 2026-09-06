// Standalone app-selection dialog for `handaan-apps`.
//
// Deliberately its own Quickshell config, separate from default/quickshell/ --
// this is a one-off dialog invoked from a terminal, not a bar widget, and has
// no reason to share the bar's singletons or module tree.
//
// handaan-apps passes the discovered apps in via HANDAAN_APPS_LIST (one
// "name\tsummary" pair per line) and reads the selection back from the file
// named by HANDAAN_APPS_OUT once this window closes. Both are environment
// variables rather than files handed to this file directly, because Quickshell
// disables XMLHttpRequest file reads by default and Quickshell.env() needs no
// such flag.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io

Window {
    id: window

    width: 420
    height: Math.min(560, 150 + list.count * 40)
    visible: true
    title: "handaan apps"
    color: "#1e1e2e"

    property var appNames: []
    property var appSummaries: []
    property var appInstalled: []
    property var checked: ({})
    // Both selectedCount and selectionText exist because two different
    // bindings (Install's enabled, and the writer Process's command) each
    // depended on a function call reading `checked`, and neither
    // re-evaluated when checked changed -- QML doesn't reliably track a
    // dependency through a property var object read inside a function call.
    // Plain properties, updated imperatively, are guaranteed to notify.
    property int selectedCount: 0
    property string selectionText: ""

    Component.onCompleted: {
        const raw = Quickshell.env("HANDAAN_APPS_LIST") || ""
        const lines = raw.split("\n").filter(line => line.length > 0)
        const initialChecked = {}
        for (const line of lines) {
            // name \t summary \t installed. Split on every tab rather than the
            // first: a summary is free text and must not be able to swallow
            // the flag after it.
            const parts = line.split("\t")
            const name = parts[0]
            const summary = parts.length > 1 ? parts[1] : ""
            const installed = parts.length > 2 && parts[2] === "1"
            appNames.push(name)
            appSummaries.push(summary)
            appInstalled.push(installed)
            initialChecked[name] = installed
        }
        checked = initialChecked
        list.model = appNames.length

        // Pre-ticked boxes have to be reflected in these two, for the reason
        // given above: nothing recomputes them from `checked`. Without this,
        // Install stays disabled until you toggle something, and the writer
        // sends an empty selection.
        const selected = appNames.filter(n => initialChecked[n])
        selectedCount = selected.length
        selectionText = selected.join("\n")
    }

    function setChecked(name, value) {
        const updated = Object.assign({}, checked)
        updated[name] = value
        checked = updated
        const selected = appNames.filter(n => updated[n])
        selectedCount = selected.length
        selectionText = selected.join("\n")
    }

    Process {
        id: writer
        // A literal script with positional params, not string interpolation --
        // the selection text reaches the child process as argv, never through
        // shell expansion, so app names can't break the quoting.
        command: ["bash", "-c", "printf '%s' \"$1\" > \"$2\"", "_",
            window.selectionText, Quickshell.env("HANDAAN_APPS_OUT")]
        onExited: Qt.quit()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                text: "Select applications to install"
                font.bold: true
                font.pixelSize: 16
                color: "#cdd6f4"
            }

            Label {
                text: "Already installed ones start ticked. Unticking removes nothing."
                font.pixelSize: 11
                color: "#a6adc8"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: list
                spacing: 4

                delegate: RowLayout {
                    width: list.width
                    spacing: 8

                    CheckBox {
                        checked: window.checked[window.appNames[index]]
                        onToggled: window.setChecked(window.appNames[index], checked)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        RowLayout {
                            spacing: 6

                            Label {
                                text: window.appNames[index]
                                color: "#cdd6f4"
                                font.bold: true
                            }

                            // A ticked box otherwise reads only as "will be
                            // installed"; this says which of them are already
                            // on the machine.
                            Label {
                                text: "installed"
                                visible: window.appInstalled[index] === true
                                color: "#a6e3a1"
                                font.pixelSize: 11
                            }
                        }
                        Label {
                            text: window.appSummaries[index]
                            color: "#a6adc8"
                            font.pixelSize: 12
                            visible: text.length > 0
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            Button {
                text: "Cancel"
                onClicked: Qt.quit()
            }

            Button {
                text: "Install"
                highlighted: true
                enabled: window.selectedCount > 0
                onClicked: {
                    if (window.selectedCount > 0) {
                        writer.running = true
                    } else {
                        Qt.quit()
                    }
                }
            }
        }
    }
}
