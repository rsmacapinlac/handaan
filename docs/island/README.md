# The island

The centre section of the bar. The bar itself, and the rules this section answers to alongside the other two, are in [The bar](../bar.md).

The island holds the ability to affect what is *happening*: See / dismiss a notification arriving, See / change media playing, or Change settings.

What it is for follows from that:

- **It should not be a second place to say something the bar already says.** If a notification surfaces here it should not also pop up elsewhere, and if it does, one of the two is the wrong surface. This is the end state rather than what is running: notifications currently appear in the island *and* as popups, deliberately, so the two can be compared before one is retired. Waybar stayed installed beside the Quickshell bar on the same reasoning, and mako stayed masked beside the shell's own notifications. Whichever loses should then go, because the rule is right.
- **It does not take the motion channel.** Appearing and leaving are transitions. Nothing in the centre may loop; see *Motion is reserved for attention* in [The bar](../bar.md).

The expansion is one surface with the cut-out rather than a separate panel underneath: the notch grows into the place where its controls live.

## The backlog badge

What the bell used to answer is the island's: *what is waiting that I have not dealt with*, and *will I be told about the next one*. The bar widget is retired.

It is a badge, not an occupant, and the distinction is the whole of why it works. Occupants are things happening now and they take turns; a backlog is not happening, it is outstanding, and it has to stay visible while something else is in the island. As an occupant it would disappear the moment media started playing, which is the one thing the bell was for.

It keeps the bell's own rules, which were right: waiting means **kept, not unseen**, so reading the history does not clear it and only dismissing or clearing does; the colour comes from the most urgent thing kept rather than the newest, so a chatty app cannot bury a critical one; and peach is not used, because that is Network's and Battery's warning and a notification is not a warning. Do-not-disturb shows as a slashed bell and holds the badge up on its own, since an empty island cannot say you have gone quiet.

**Clicking the cut-out expands the island**, exposing its notification history, media controls and do-not-disturb switch, and clicking it again collapses it. It also opens when empty. The separate history dialog remains available through `Super+Shift+N` or `handaan notifications`.

## Two states

The island is either a **cut out** or **expanded**, and expanding is the cut-out growing rather than something new appearing beside it.

- **Cut out** is the small shape: a notch in the bar, carrying what fits at that size.
- **Expanded** is that same shape grown, with a standard window inside it showing the content in full. Its width is a share of the screen it opened on rather than a pixel count -- `Style.islandWidthFraction`, 40% today -- so the island is the same proportion of a 1536-wide laptop panel as of a 2560-wide external one. A fixed number was a quarter of the one and a seventh of the other, which read as two different surfaces.

**Expansion is on click, never on hover or arrival.** Something arriving takes the cut-out; it does not open the island by itself.

That puts a floor under the cut-out. *No interaction is ever required to read* is one of [the bar's](../bar.md) rules, so whatever is in the island has to be answerable at cut-out size -- who is telling you something, that media is playing. Expansion is for the detail and for acting on it, not for finding out there was anything there.

**It stays open until you click outside it, or on the cut-out again.** The cut-out is the handle at either size, so the thing that opened the island is the thing that closes it. Only the strip does: everything below it is what you opened the island to act on, and a click that dismissed a notification and collapsed the island in one gesture would take the surface away mid-task. Moving the pointer away does not collapse it, clicks on its controls leave it open, and clearing the last notification does not close it either.

Outside clicks are handled by `HyprlandFocusGrab` on the bar window, plus a handler for clicks elsewhere inside that same bar. Expansion is local to the monitor you clicked; notification and media state remain shared. Hover does not expand the island or take keyboard focus.

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
- **The island reads session-wide state, deliberately.** The bar's standing rule is that a widget answering anything about "this screen" must use its injected screen and never a global. The island is the exception and has to be: it answers nothing about the screen it is on, so a per-screen answer would be the bug rather than the fix.

## It lives in the bar

The island is drawn in the bar's own window rather than one of its own. That lets the cut-out and the expansion be a single shape as it grows and collapses.

Everything above is written for a horizontal bar. What a vertical one does is open: the centre of a side bar is the middle of a screen edge rather than the top of the screen, and the cut-out's budget there is the card text column -- 78px -- instead of as much width as it needs, so both the shape and the readability floor change.

**An island pinned to the top of the screen regardless of where the bar is was considered, and the layer shell rules it out.** A surface's exclusive zone is reserved along the whole edge it is anchored to, not merely behind the surface itself, so an always-top island that reserved space would hand a side-bar machine a second full-width strip with a notch in the middle of it. Not reserving is the only alternative, and that means floating over window content permanently, which is not something a permanent cut-out can do. Recorded so it is not proposed again.

## Open decisions

Three remain:

1. **Precedence, beyond the first rule.** An event outranks a state, so a notification takes the island while it lasts and media is still underneath when it goes. That settles the pair that exists. It does not settle what happens when settings arrive -- they are neither an event nor something the island can be *showing* in the same sense -- nor what two notifications at once should do, where the island currently shows the newest and says nothing about the rest.
2. **Whether anything ever forces expansion.** Nothing does today, including critical notifications. Expansion requires a click.
3. **What the island does on a vertical bar.** Nothing above answers it, and the always-top escape is closed. Either it transposes and the cut-out becomes close to icon-only, or the island is a thing horizontal bars have and side bars do not.

Separately, *it is not a second place to say something the bar already says* is not satisfied yet. [0008](../decisions/adrs/0008-notifications-are-part-of-the-desktop-shell.md) has been edited for the island and the edit is in the [CHANGELOG](../decisions/adrs/CHANGELOG.md) — the popups moved to the centre under the island rather than staying at the top right — but both surfaces still run, which is the comparison the first rule above describes. Retiring one of them is what closes this.
