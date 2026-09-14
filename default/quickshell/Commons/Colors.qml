// The raw palette, taken from the wallpaper.
//
// handaan-wallpaper-set derives it from each new wallpaper and writes
// $HANDAAN_STATE/theme/colors.json, which this watches. Any colour
// that file does not carry comes from default/theme/fallback.json, so the shell
// is themed before the first wallpaper is ever set and survives a derivation
// that failed.
//
// These names describe a colour's place in the palette, not its hue: a
// wallpaper has no "mauve". Widgets still bind to Theme, never to this file, so
// what each colour is *for* is decided in one place.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Bound to text() rather than set from onLoaded: with blockLoading the
    // first read waits for the file, so the very first evaluation already has
    // the palette, and text() notifies when a reload changes it.
    readonly property var fallback: root.parse(fallbackFile)
    readonly property var derived: root.parse(derivedFile)

    readonly property color background: root.pick("background")
    readonly property color backgroundDeep: root.pick("backgroundDeep")
    readonly property color surface: root.pick("surface")
    readonly property color surfaceHover: root.pick("surfaceHover")
    readonly property color border: root.pick("border")
    readonly property color text: root.pick("text")
    readonly property color textMuted: root.pick("textMuted")
    readonly property color accent: root.pick("accent")
    readonly property color accentAlt: root.pick("accentAlt")
    readonly property color good: root.pick("good")
    readonly property color warning: root.pick("warning")
    readonly property color critical: root.pick("critical")

    // Per colour, so a derived file missing or mangling one key costs only that
    // key, not the whole palette.
    function pick(name) {
        for (const source of [root.derived, root.fallback]) {
            const hex = source[name];
            if (typeof hex === "string" && /^[0-9a-fA-F]{6}$/.test(hex))
                return "#" + hex;
        }
        return "#000000";
    }

    function parse(file) {
        try {
            return JSON.parse(file.text());
        } catch (e) {
            return {};
        }
    }

    FileView {
        id: fallbackFile

        path: Quickshell.shellDir + "/../theme/fallback.json"
        blockLoading: true
    }

    FileView {
        id: derivedFile

        path: (Quickshell.env("HANDAAN_STATE") || Quickshell.env("HOME") + "/.local/state/handaan") + "/theme/colors.json"
        blockLoading: true
        printErrors: false

        // Watched, so a new wallpaper recolours the shell without anything
        // having to reach it. The file is renamed into place rather than
        // rewritten, and the watch follows the new file as well as the first
        // one appearing.
        watchChanges: true
        onFileChanged: reload()
    }
}
