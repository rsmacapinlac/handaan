// Structural style tokens: everything the shell can be themed by that is not
// a colour. Sizes are in logical pixels, so Hyprland's per-monitor scaling
// (1.25 on eDP-1, 1 on the external) is applied by the compositor and nothing
// here needs to know which screen it is drawing on.

pragma Singleton
import QtQuick

QtObject {
    id: root

    // --------------------------------------------------------------- fonts
    // Matches kitty and the waybar config this replaces, so glyph metrics and
    // the Nerd Font icon set stay consistent across the desktop.
    readonly property string fontFamily: "BlexMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int fontSizeSmall: 11

    // ----------------------------------------------------------- dimensions
    readonly property int barSize: 34
    // A side bar's thickness. Unlike barSize, which is the height a row of
    // widgets needs, this is a budget: the screen width given up to a vertical
    // bar, which the widgets in it divide between them. The workspace grid is
    // what spends it -- five pills across, sized from this number rather than
    // fixed, so changing it here resizes them instead of clipping them.
    readonly property int barSideSize: 120
    readonly property int radius: 8
    readonly property int borderWidth: 1

    // ------------------------------------------------------------- spacing
    // One scale, used everywhere, so padding stays proportional if the bar
    // grows. space(1) is the base unit; widgets ask for multiples.
    readonly property int spaceUnit: 4

    function space(multiplier) {
        return Math.round(root.spaceUnit * multiplier);
    }

    // Gap between adjacent widgets in a bar section. Deliberately wide: with no
    // separator chrome in the bar, whitespace is the only thing grouping a
    // widget's own parts against its neighbours. It therefore has to be clearly
    // larger than any spacing used *inside* a widget -- the clock's date-to-time
    // gap is space(2) -- or adjacent widgets read as one run of glyphs.
    readonly property int widgetSpacing: space(5)
    // Inset from the bar's leading and trailing screen edges.
    readonly property int barPadding: space(3)
    // The same inset along a side bar's short axis, where the budget above is
    // tight enough that the wider one would cost a pill's worth of width.
    readonly property int barSidePadding: space(1.5)
    // Horizontal padding inside a single widget's hit area.
    readonly property int widgetPadding: space(2.5)

    // ------------------------------------------------------- side-bar cards
    // Every widget on a side bar is one card: an icon in a fixed rail on the
    // left, and up to two lines beside it. The rail is reserved whether or not
    // a card has an icon to put in it, because the alignment is the point --
    // five cards whose text all starts at the same x read as one column, and
    // five centred on their own differing widths read as five unrelated
    // widgets that happen to be stacked.
    //
    // The rail is sized from the battery's body, the widest icon and the only
    // one that is a drawn shape rather than a glyph. Everything else centres
    // in it.
    readonly property int barCardRail: space(6)
    readonly property int barCardGap: space(1.5)
    readonly property int barCardWidth: barSideSize - barSidePadding * 2
    // What is left for text: the ceiling every line has to fit, which is what
    // makes "maximum two lines" a rule the card can actually enforce rather
    // than a habit each widget keeps on its own.
    readonly property int barCardText: barCardWidth - barCardRail - barCardGap

    // Hyprland's outer gap, general.gaps_out in default/hypr/look.lua. A
    // surface that sits beside windows -- the notification popups and history
    // -- keeps this distance from the bar and the screen edge, so its border
    // lines up with the windows' borders. Change the two together.
    readonly property int windowGap: 3

    // -------------------------------------------------------------- motion
    readonly property int animationFast: 120
    readonly property int animationNormal: 240
}
