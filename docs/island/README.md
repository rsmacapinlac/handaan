# The island

The centre section of the bar. The bar itself, and the rules this section answers to alongside the other two, are in [The bar](../bar.md).

The island holds the ability to affect what is *happening*: See / dismiss a notification arriving, See / change media playing, or Change settings.

What it is for follows from that:

- **It should not be a second place to say something the bar already says.** If a notification surfaces here it should not also pop up elsewhere, and if it does, one of the two is the wrong surface. This is the end state rather than what is running: notifications currently appear in the island *and* as popups, deliberately, so the two can be compared before one is retired. Waybar stayed installed beside the Quickshell bar on the same reasoning, and mako stayed masked beside the shell's own notifications. Whichever loses should then go, because the rule is right.
- **It does not take the motion channel.** Appearing and leaving are transitions. Nothing in the centre may loop; see *Motion is reserved for attention* in [The bar](../bar.md).

The expansion is one surface with the cut-out rather than a separate panel underneath: the notch grows into the place where its controls live.

## The backlog badge

What the bell used to answer is the island's: *what is waiting that I have not dealt with*, and *will I be told about the next one*. The bar widget is retired.

It is a badge, not an occupant, and the distinction is the whole of why it works. Occupants are things happening now and they take turns; a backlog is not happening, it is outstanding, and it has to stay visible while something else is in the island. As an occupant it would disappear the moment a notification took context, which is the one thing the bell was for.

It keeps the bell's own rules, which were right: waiting means **kept, not unseen**, so reading the history does not clear it and only dismissing or clearing does; the colour comes from the most urgent thing kept rather than the newest, so a chatty app cannot bury a critical one; and peach is not used, because that is Network's and Battery's warning and a notification is not a warning. Do-not-disturb shows as a slashed bell and holds the badge up on its own, since an empty island cannot say you have gone quiet.

**Clicking the cut-out expands the island**, exposing its notification history, media controls and do-not-disturb switch, and clicking it again collapses it. It also opens when empty. `Super+Shift+N` (or `handaan island`) does the same from the keyboard, on the focused monitor's island. The separate history dialog remains available through `handaan notifications`.

## Two sections

The cut-out is divided in two: **context** on the left, **status** on the right, with a thin rule between them when both have something to say.

**Context says what you are in.** It names the app of the window in front on that monitor, and on the monitor that has focus it adds the window's title, muted, after the name. The title is therefore also how you tell which screen your keys go to. Most titles end by naming their app -- "— Mozilla Firefox" -- and that tail is cut, since the name is already there. The name comes from the app's desktop entry, else the tail of its app id. Name and title share one width ceiling, `Style.islandCutoutText`, and the title gives way first.

A notification is an event and takes context while it lasts, marked with a bell so it does not read as an app name, then hands context back to the window. An event outranks a state.

**Status holds badges, which never take turns**, because each is something you must not lose sight of while something else is in context:

- **Capture** -- a red dot while anything reads the camera, the microphone or the screen. It is the one loud colour in the cut-out because being recorded without knowing is the case worth it, and it is still, because it is a state rather than a request for a response. It reads PipeWire: an app capturing is an input stream, and a portal screen share is `xdg-desktop-portal-hyprland`'s own `xdph-streaming-*` node. A recorder that uses `wlr-screencopy` directly never touches PipeWire and is not seen, and a volume meter such as pavucontrol's opens an input stream and is.
- **Media** -- play or pause. Only whether something is playing; the track is the expanded island's.
- **Backlog** -- the bell, below.

With nothing in either section the cut-out is a bare pill, `Style.islandCutoutMinWidth` wide, so the handle is still big enough to hit. It used to carry an ellipsis there, which read as text cut off rather than as nothing going on.

## Two states

The island is either a **cut out** or **expanded**, and expanding is the cut-out growing rather than something new appearing beside it.

- **Cut out** is the small shape: a notch in the bar, carrying what fits at that size.
- **Expanded** is that same shape grown, with a standard window inside it showing the content in full. It holds two columns -- the player on the left, what is waiting on the right -- and its width is those two plus the margins around them, `Style.islandWidth`. The width is fixed, so the island is one size on every monitor and is learned once; a share of the screen was tried first and made it 614px on a 1536-wide laptop panel against 1024px on a 2560-wide external, which is one surface at two sizes. The notification column is sized from a notification card's own width, so a card is not a different width for being read here.

## What the expanded island holds

- **Left column: what is playing, and how you hear it.** The player; then the output, as a picker listing every output device with the current one ticked, and beside it a button that opens Blueman; the output's volume and mute; and the microphone's mute, warning-coloured while muted so a muted call is caught at a glance. Moving the volume unmutes, as turning a knob would. These are WirePlumber's defaults, so they are session-wide like the player: one machine has one output whichever monitor you change it from.
- **Below them, connected Bluetooth devices,** each with its battery where the device reports one and a button to disconnect it. Only connected devices are listed. Pairing and connecting belong to Blueman, through the button beside the output, so with nothing connected the section and its rule are gone rather than standing empty. There is no Bluetooth power switch: it would live in a section that disappears when nothing is connected.
- **Right column: what is waiting,** with do-not-disturb and Clear all.
- **Across the bottom, the session:** the power menu's five actions in a row the island's full width, with the power menu's own rule -- lock and suspend act on the first click, while log out, restart and shut down arm on the first and act on the second. A line under the row says what the second click will do, and holds its height when empty so arming does not resize the island. `Escape` disarms before it closes. They are `SessionControl`'s actions run through `SessionControl.run`, so the island and the power menu cannot drift; the power menu stays where `Ctrl+Alt+Delete` reaches it, because that key is pressed when the bar may not be usable.

**Expansion is on click, never on hover or arrival.** Something arriving takes the cut-out; it does not open the island by itself.

That puts a floor under the cut-out. *No interaction is ever required to read* is one of [the bar's](../bar.md) rules, so whatever is in the island has to be answerable at cut-out size -- who is telling you something, what you are in, that media is playing, that you are being recorded. Expansion is for the detail and for acting on it, not for finding out there was anything there.

**It stays open until you click outside it, click the cut-out again, or press `Escape` or `Super+Shift+N`.** The cut-out is the handle at either size, so the thing that opened the island is the thing that closes it. Only the strip does: everything below it is what you opened the island to act on, and a click that dismissed a notification and collapsed the island in one gesture would take the surface away mid-task. Moving the pointer away does not collapse it, clicks on its controls leave it open, and clearing the last notification does not close it either.

Outside clicks are handled by `HyprlandFocusGrab` on the bar window, plus a handler for clicks elsewhere inside that same bar. Expansion is local to the monitor you clicked; notification and media state remain shared. Hover does not expand the island or take keyboard focus. The bar takes the keyboard only while its island is open -- exclusively, as the shell's dialogs do -- so `Escape` can close it; closed, it never takes typing away from a window.

It is drawable as described. `PanelWindow` takes an `exclusiveZone` independently of its size, so the bar's window can grow downward past its 44px while still reserving only 44px -- windows below stay where they are. The overflow is transparent and would otherwise swallow every click across the top of the screen, so the window's `mask` has to be the bar's rectangle plus the island's current shape, and has to follow it as it grows.

Expanding and collapsing are transitions, which the motion rules allow: they are bounded and over before you look. Nothing may loop at either size. It is the largest movement the bar makes -- in the middle of the screen, changing the bar's outline rather than something inside it -- and what makes that acceptable is that you asked for it. The same movement arriving unbidden, several times an hour, would not be.

**The cut-out is always there.** It was an open question while the island only displayed what was happening, because a notch with nothing in it would have been chrome -- and *information you would never act on does not belong in the bar* is a rule the other two sections are held to. Making the island a place to *act* settles it: settings are always available, so there has to be somewhere to reach them, and a notch that appeared only when something arrived would change the bar's outline every time a notification came in.

It survives the rule because it is not information. It is the handle: what you act on is inside it, and the shape itself says only that things go here.

## Notification scrolling

The expanded island shows a viewport sized for the four newest notification cards. Further notifications are reached by scrolling with the wheel, touchpad or scrollbar. The scrollbar appears only when the list overflows, and the existing height ceiling still applies when four long cards would make the panel too tall. Media controls, do-not-disturb and Clear all stay outside the scrolling list. Dismissing cards shrinks the list when fewer than four remain.

## Every monitor

The island is on every monitor, the way the rest of the bar is. It is not gated to the focused one.

Two things follow, and they are requirements rather than consequences to discover later:

- **The islands are views onto one state, not several.** A notification dismissed on one screen is gone from all of them, and media paused on one is paused everywhere, because there is one notification centre and one player. This is the ordinary singleton arrangement -- `Commons/` owns the state, the surfaces draw it.
- **The island reads session-wide state, except for context.** The bar's standing rule is that a widget answering anything about "this screen" must use its injected screen and never a global. Notifications, media, capture and the backlog answer nothing about the screen they are on, so a per-screen answer there would be the bug rather than the fix. Context is the one per-screen answer: it reads `Hyprland.monitorFor(screen)` and its active workspace, and remembers the window that monitor last had focused, so a monitor that loses focus still names what is on it.

## It lives in the bar

The island is drawn in the bar's own window rather than one of its own. That lets the cut-out and the expansion be a single shape as it grows and collapses.

Everything above is written for a horizontal bar. What a vertical one does is open: the centre of a side bar is the middle of a screen edge rather than the top of the screen, and the cut-out's budget there is the card text column -- 78px -- instead of as much width as it needs, so both the shape and the readability floor change.

**An island pinned to the top of the screen regardless of where the bar is was considered, and the layer shell rules it out.** A surface's exclusive zone is reserved along the whole edge it is anchored to, not merely behind the surface itself, so an always-top island that reserved space would hand a side-bar machine a second full-width strip with a notch in the middle of it. Not reserving is the only alternative, and that means floating over window content permanently, which is not something a permanent cut-out can do. Recorded so it is not proposed again.

## Open decisions

Three remain:

1. **Precedence, beyond the first rule.** Badges never compete, and in context an event outranks a state, so a notification takes context while it lasts and the window is still underneath when it goes. That settles what exists. It does not settle what happens when settings arrive -- they are neither an event nor something the island can be *showing* in the same sense -- nor what two notifications at once should do, where the island currently shows the newest and says nothing about the rest.
2. **Whether anything ever forces expansion.** Nothing does today, including critical notifications. Expansion requires a click.
3. **What the island does on a vertical bar.** Nothing above answers it, and the always-top escape is closed. Either it transposes and the cut-out becomes close to icon-only, or the island is a thing horizontal bars have and side bars do not.

Separately, *it is not a second place to say something the bar already says* is not satisfied yet. [0008](../decisions/adrs/0008-notifications-are-part-of-the-desktop-shell.md) has been edited for the island and the edit is in the [CHANGELOG](../decisions/adrs/CHANGELOG.md) — the popups moved to the centre under the island rather than staying at the top right — but both surfaces still run, which is the comparison the first rule above describes. Retiring one of them is what closes this.
