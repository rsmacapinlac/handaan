// The wallpapers on offer, which one is up, and whether the picker is open.
//
// A singleton for the reason AppCatalog and SessionControl are: the surface
// that draws the picker, Ui/WallpaperPicker.qml, is loaded on demand, and a
// thing that is not loaded cannot receive the IPC call asking it to appear.
// This is always resident, holds the open state, and carries the `wallpapers`
// target that Super+Shift+W reaches through bin/handaan-wallpaper.
//
// It must be reached as `qs.Commons.Wallpapers`, never by relative path -- a
// pragma Singleton imported by path is instantiated once per importing file.
// The surface is named differently on purpose: a type sharing a name with a
// singleton imported into it shadows that singleton silently.
//
// The list comes from handaan-wallpaper-manifest and choosing one runs
// handaan-wallpaper-set, so the shell holds no opinion about where wallpapers
// live or how one is applied. Colours are not handled here at all: setting the
// wallpaper writes a new palette, and Colors follows the file.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // { path, name, origin, credit }, yours first. `loaded` tells an empty list
    // from an unread one, and `error` tells a failed read from an empty folder.
    property var entries: []
    property bool loaded: false
    property string error: ""

    property bool pickerOpen: false

    // What is on screen, as handaan-wallpaper-set records it. Watched, so the
    // picker marks the right one even when the change came from somewhere else.
    readonly property string current: currentFile.text().trim()

    readonly property string handaanPath: Quickshell.env("HANDAAN_PATH") || (Quickshell.env("HOME") + "/.local/share/handaan")

    // Re-read on every open: a wallpaper dropped into ~/.config/handaan/wallpapers
    // since the last one should simply be there.
    function open() {
        if (!manifest.running)
            manifest.running = true;
        root.pickerOpen = true;
    }

    function close() {
        root.pickerOpen = false;
    }

    function toggle() {
        if (root.pickerOpen)
            root.close();
        else
            root.open();
    }

    // Closes first, so the new wallpaper is not hidden behind the picker. The
    // set takes a moment -- hyprpaper, then the palette -- and nothing here
    // waits for it; execDetached double-forks, so it outlives a shell restart.
    function set(path) {
        root.close();
        Quickshell.execDetached([root.handaanPath + "/bin/handaan-wallpaper-set", path]);
    }

    function random() {
        root.close();
        Quickshell.execDetached([root.handaanPath + "/bin/handaan-wallpaper-set", "--random"]);
    }

    FileView {
        id: currentFile

        path: Quickshell.env("HOME") + "/.wallpaper"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
    }

    Process {
        id: manifest

        command: [root.handaanPath + "/bin/handaan-wallpaper-manifest"]

        onExited: function (exitCode) {
            if (exitCode !== 0) {
                root.error = "handaan-wallpaper-manifest exited " + exitCode;
                root.loaded = true;
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                var parsed;
                try {
                    parsed = JSON.parse(this.text);
                } catch (e) {
                    root.error = "could not read the wallpaper list: " + e;
                    root.loaded = true;
                    return;
                }
                if (!Array.isArray(parsed)) {
                    root.error = "the wallpaper list was not a list";
                    root.loaded = true;
                    return;
                }
                root.error = "";
                root.entries = parsed;
                root.loaded = true;
            }
        }
    }

    IpcHandler {
        target: "wallpapers"

        // What Super+Shift+W calls, so a second press puts the picker away.
        function toggle(): string {
            root.toggle();
            return root.pickerOpen ? "opened" : "closed";
        }

        function open(): string {
            root.open();
            return "opened";
        }

        function close(): string {
            root.close();
            return "closed";
        }
    }
}
