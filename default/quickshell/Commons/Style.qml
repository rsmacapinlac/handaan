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
    // A top bar's height. Not the height the content needs -- a card's two
    // stacked lines measure 27px -- but that plus the air either side of it,
    // because nothing insets a row on a top bar: WidgetRow takes this height
    // whole and every widget centres inside it, so the margin above and below
    // a card IS (barSize - content) / 2. At 44 that is about 8px each way.
    //
    // Raising it does not enlarge anything: the workspace pill is a fixed
    // space(5.5) centred in its slot, and a card's lines are centred too, so
    // this only ever buys clearance. Lowering it past the content is what
    // clips, and the first thing to clip is a card's second line.
    readonly property int barSize: 44
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
    // larger than any spacing used *inside* a widget -- the widest of those is
    // barCardRowGap below -- or adjacent widgets read as one run of glyphs.
    //
    // It moves with that gap rather than independently: the two are a ratio,
    // not two numbers. Widening the space between a card's icon and its text
    // without widening this one closes the difference the rule depends on.
    readonly property int widgetSpacing: space(6)
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
    // The same icon-to-text gap on a top bar. A separate number because this
    // one answers to legibility alone, where barCardGap above is also a term
    // in the barCardText arithmetic -- widening that one narrows the side
    // bar's text column by the same amount.
    readonly property int barCardRowGap: space(2.5)

    // The island's cut-out. A ceiling on the text rather than a width for the
    // shape: the shape is as wide as its content, and this stops one long
    // track title from pushing the bar's centre around as tracks change.
    readonly property int islandCutoutText: space(40)

    // The island's expanded half, below the cut-out strip. Stated rather than
    // taken from the content: it is a window, and a window that changed size
    // with every track would be the shape moving while you were reading it.
    readonly property int islandWidth: space(96)
    readonly property int islandHeight: space(34)
    readonly property int islandArt: space(20)

    // How far down the screen the island may reach when it is holding every
    // notification. A ceiling rather than a size: it is as tall as it needs to
    // be until it would be most of the screen, and then it scrolls.
    readonly property int islandMaxStack: space(140)
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
