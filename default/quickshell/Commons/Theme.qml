// Semantic colour roles for the shell.
//
// Widgets bind to the roles here, never to Colors directly. The palette names
// a colour's place in the scheme ("accent"); this names what it is *for* ("the
// focused workspace"). Keeping the indirection means a new wallpaper never
// touches a widget, and a role can be retargeted in one place.
//
// The severity ladder is blended toward the wallpaper but never leaves its hue
// -- see default/theme/palette.jq. Their hue is the meaning, and a green that
// drifted to teal could no longer be trusted to read as "fine".

pragma Singleton
import QtQuick

QtObject {
    id: root

    // ------------------------------------------------------------------ bar
    readonly property color barBackground: Colors.background
    // The bar strip itself, translucent so the compositor's blur shows through
    // (default/hypr/rules.lua). A separate role from barBackground on purpose:
    // that one is also used as solid ink -- the numeral on the focused
    // workspace pill, the installer's panels -- and must stay opaque there.
    readonly property color barSurface: Qt.alpha(Colors.background, 0.8)
    readonly property color barText: Colors.text
    readonly property color barTextMuted: Colors.textMuted

    // Accent for the focused workspace, and anything else that should read as
    // "this one, right now".
    readonly property color active: Colors.accent

    // A summoned dialog drawn over windows rather than wallpaper. Less
    // translucent than barSurface: nothing blurs behind it, and text over a
    // busy window has to stay legible.
    readonly property color dialogSurface: Qt.alpha(Colors.background, 0.9)

    // ----------------------------------------------------------------- lock
    // Under the wallpaper, and all there is when there is no wallpaper. Opaque:
    // whatever was on the screen when you walked away must not show through.
    readonly property color lockBackground: Colors.backgroundDeep
    // Laid over the wallpaper so the clock and the password field stay legible
    // on a bright image. Stronger than dialogSurface, because a wallpaper is
    // busier than any window.
    readonly property color lockScrim: Qt.alpha(Colors.backgroundDeep, 0.55)

    // ------------------------------------------------------------- surfaces
    readonly property color surface: Colors.surface
    readonly property color surfaceHover: Colors.surfaceHover
    readonly property color border: Colors.border

    // Hyprland marks a workspace urgent when a window on it wants attention.
    readonly property color urgent: Colors.critical

    // --------------------------------------------------------------- levels
    // Severity, for widgets reading a measurement rather than a state. One
    // shared ladder, so "this is getting low" looks the same wherever it
    // appears and the eye only has to learn it once.
    readonly property color good: Colors.good
    readonly property color warning: Colors.warning
    readonly property color critical: Colors.critical
}
