# Widgets

This document governs the design language of the **widgets section** — the bar's right side, the only one built from cards. The bar itself and its other two sections are in [The bar](bar.md), whose rules on glance-ability, motion and interaction hold here too.

What is true of one widget rather than of all of them — the questions it answers, and where it departs from this document — is in its own record under [`quickshell/widgets/`](quickshell/widgets/README.md).

## Every widget is a card

A card is one widget's answer to its questions, in a shape it shares with every other card. `Ui/BarCard.qml` is that shape. A bar whose widgets each solved their own layout would be a stack of unrelated things that happen to share an edge, and the shared shape is what makes it a column instead.

Cards stack. The bar runs vertically by default, so a card is read down the bar with its neighbours — which is where the shared shape earns itself: five cards whose text all begins at the same x read as one column, and five centred on their own differing widths read as five widgets. The same card lays out as a row on a top bar, icon then the lines beside each other, so a widget's content is declared once rather than twice. One visible consequence there: the accessory — the slot beside line one, for the one thing a string cannot carry, such as a glyph needing a colour of its own — follows the icon instead of preceding it, so the battery reads body-then-bolt rather than bolt-then-body. The card puts the icon first, always.

## Two columns

A card is two columns: **an icon, and the information it introduces.** The icon sits in a fixed rail; the information column takes the majority of the width, because the information is what the card is for.

Three numbers, in `Commons/Style.qml`:

| token | value | where it comes from |
|---|---|---|
| `barCardWidth` | 108 | `barSideSize` less the side padding either side |
| `barCardRail` | 24 | the battery's body and cap — the widest icon, and the only one that is a drawn shape rather than a glyph |
| `barCardText` | 78 | what is left |

The rail is reserved whether or not a card has an icon for it, and the majority is reserved whether or not a card has a line to put there. Both reservations *are* the alignment: a card that reclaimed the width it was not using would put its rail at a different x from the card above it, which is the one thing the shared shape exists to prevent. Reserved is not the same as occupied — the majority is the card's budget for information, not a quota it has to meet.

## The icon says what the card is and how it stands

The icon carries two things: **what the card is and how it stands.** Identity alone would be a label, and a label answers nothing — you already know which card is the battery, so a glyph that only says "battery" is spending the rail to tell you what you came in knowing. The icon earns its column by encoding state as well: the battery's fill length and ladder colour, the Bell's colour and its slash.

**Where a widget has no state, the icon is identity alone and says so.** The Clock is the case: its two lines already carry everything it answers, so there is nothing left for the rail to encode. That is not licence to skip the second half wherever it is inconvenient — the test is whether a state exists that the icon *could* carry, not whether one was easy to find. The failure to avoid is an icon that manufactures a state to comply: an hour-hand clock face encodes the hour the time already prints, at a resolution the rail cannot show, and would let the card claim the rule while carrying a worse version of its own line.

## A card with nothing to say disappears

A card leaves the bar when it has nothing relevant to show. `BarWidget.active` drops the widget **and its spacing**, so an up-to-date machine carries no update chrome whatsoever.

Absence is an encoding, not a tidy-up — presence is the whole of Updates' glance layer, and the strongest signal available, because the two states are "a card" and "no card" and nothing else has to be read to tell them apart. But absence says two different things and they are worth keeping apart: *there is nothing to do* (Updates, the Bell) and *there is no answer to give* (the battery on a machine without one, Network while connectivity is unknown). Both render as the same absence. So a card may only use presence as its answer when its question is of the first kind; a card that disappears because it does not know is silent about the fact that it does not know.

## Cards can reveal more

A card answers at a glance and can be asked for more. The asking has two forms, and they must not be confused:

- **Hover sharpens the answer.** The same question at higher resolution, taking no focus and destroying nothing. `Ui/Tooltip.qml`, governed by *Detail is progressively disclosed* below.
- **Click opens somewhere to act on the card's subject.** Not more detail — somewhere to do something about it. The Bell's history is the worked example: it dismisses, clears and toggles do-not-disturb, which is why it holds keyboard focus and why a tooltip could never have been it. A card with nothing to act on gets no click handler, which is why the battery has none.

**The drawer is an experiment.** What a card opens is a drawer: full height, against the bar's inner edge, one fixed width, in the same place whichever card opened it. One position, learned once. It was chosen over anchoring the panel to the card — which moves with the card's place in the bar and with the height of its content, leaving nowhere to learn — and over the centred dialog the installer, power menu and wallpaper picker share, which covers the window being read and is the heaviest gesture available for "show me a bit more".

Nothing is built, and the problem that prompted it has since gone. The drawer came up because the notification history is anchored top right while the Bell that opens it sat at the bottom of a right-hand bar, so clicking the bell threw a panel diagonally across the screen. The bar has moved back to the top; the bell and the panel are both top right again, and the diagonal throw went with the layout that caused it.

So this is an idea without a complaint behind it, which is worth saying plainly rather than leaving it to look like pending work. Revisit it if a second card earns something to reveal, or if the bar moves again. One drawer was never evidence; the question was whether two of them in the same place read as one habit or as a surface that keeps showing unrelated things.

## Detail is progressively disclosed

A widget shows one thing at a glance and can be asked for more. That gives it three layers:

1. **The glance layer** is always visible and answers the widget's questions.
2. **The hover layer** answers the *same questions*, more precisely. It is detail on request.
3. **Post action layer** holds everything else.

The hover layer is a speech bubble with a tail on the edge facing the bar, `Ui/Tooltip.qml`. The tail says which card is talking, which a floating panel beside a column of five cannot: they are one widget-spacing apart, and a bubble that merely appeared near them would leave you counting. **The tail points at the widget, not at the middle of the bubble** — a bubble too tall for the room beside its card is slid back onto the screen, and a tail fixed to the centre would then point at a neighbour. It is read from where the bubble was actually placed rather than predicted.

**The bubble stands clear of the bar rather than growing out of it.** A tail whose tip meets the bar reads as a panel the bar has extruded, and the shape stops saying "this card is answering" the moment it becomes continuous with every other card's edge. The clearance is measured from the bar's own edge, not from the widget: on a side bar the card is inset by `barSidePadding`, so a gap measured from the card spends most of itself crossing that inset and arrives at nothing. `barClearance` is the number, and it is deliberately larger than `Style.windowGap` — the notification surfaces sit at the window gap because they line up with the window borders beside them, while this one has to read as detached from the bar it points at.

Two things this section has already been got wrong on, both worth keeping in front of the next reader. The gap is reserved as transparent window on the bar-facing side, **not** asked for as an anchor margin; `PopupAnchor.margins` applies to the anchor rect and does not move the popup, so asking that way left the tail flush against the bar while the arithmetic said otherwise. And the tail's size is what makes it legible against a 34px card, so it is not free to shrink: below about eight pixels of protrusion it disappears into the bubble's own corner radius.

## Breaking the pattern

A card follows the shape unless there is a reason not to, and **a reason not to is written down in that widget's record.** An undocumented deviation cannot be told apart from an oversight, and the next person to look at it — including the one who wrote it — has no way to know whether they are reading a decision or a bug.

None is standing today. Workspaces used to be listed here, as a grid of pills that is not a card; it is not a deviation any more, because it is not in this section — see [the workspaces section](#the-workspaces-section). The Clock used to be the other, as the one card with an empty rail. It is not a deviation any more: it takes an icon like every other card, and the rule above carries the identity-only case its argument turned out to be about.

## Checklist for a new widget

Before writing one:

- [ ] What one or two questions does this answer? Write them down.
- [ ] Would knowing this change what I do next? If not, it is not a widget.
- [ ] Which two states are strong? What recedes?
- [ ] Does every stated question have a visible encoding?
- [ ] Is the widget fully readable with no interaction at all?
- [ ] Does anything here move? If so, does it mean "needs a response", is it the
      only moving thing, does it stop on its own, and is the state still
      readable without it?
- [ ] If it has a tooltip: cover it. Does the widget still answer its questions
      without it, and does the tooltip answer those same questions more
      precisely rather than smuggling in a new one?
- [ ] Does anything fire on scroll or hover that I would regret?
