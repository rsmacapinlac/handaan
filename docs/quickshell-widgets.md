# Quickshell Widget Design

This document governs the design language of the bar widget. What is true of one widget rather than of all of them — the questions it answers, and where it departs from this document — is in its own record under [`quickshell/widgets/`](quickshell/widgets/README.md).

## The principle: Each widget on the bar should be glance-able

## Building a widget

When building a widget, you *must* follow these principles.

Each widget has to have a defined purpose and its purpose is supported by these questions:

1. *What question does the module answer before you design it.* Examples: Battery: "do I need to find a cable." Network: "is my connection working." Workspaces: Which workspace am I on? A widget cannot be built without this. 
2. **Information you would never act on does not belong in the bar.** Remove any "extra" information, design elements unless they directly serve the question. Question every element that is displayed.

### States compete for legibility

A widget communicates by making states *distinguishable*. Each additional state it tries to distinguish makes every other state harder to pick out, because the available signals (ie. colour, brightness, size, shape) are shared and finite.

So:

- **Two states may be strong. Everything else recedes.** The strong states are the answers to the widget's questions.
- **Do not encode a state the questions did not ask for.** A state that answers no question is spending legibility for nothing.
- **A question with no encoding is a bug.** A widget is not doing its job if it does not expose the necessary information that answers the key question and purpose.

## Every widget is a card

A card is one widget's answer to its questions, in a shape it shares with every other card. `Ui/BarCard.qml` is that shape. A bar whose widgets each solved their own layout would be a stack of unrelated things that happen to share an edge, and the shared shape is what makes it a column instead.

Cards stack. The bar runs vertically by default, so a card is read down the bar with its neighbours — which is where the shared shape earns itself: five cards whose text all begins at the same x read as one column, and five centred on their own differing widths read as five widgets. The same card lays out as a row on a top bar, icon then the lines beside each other, so a widget's content is declared once rather than twice. One visible consequence there: the accessory — the slot beside line one, for the one thing a string cannot carry, such as a glyph needing a colour of its own — follows the icon instead of preceding it, so the battery reads body-then-bolt rather than bolt-then-body. The card puts the icon first, always.

### Two columns

A card is two columns: **an icon, and the information it introduces.** The icon sits in a fixed rail; the information column takes the majority of the width, because the information is what the card is for.

Three numbers, in `Commons/Style.qml`:

| token | value | where it comes from |
|---|---|---|
| `barCardWidth` | 108 | `barSideSize` less the side padding either side |
| `barCardRail` | 24 | the battery's body and cap — the widest icon, and the only one that is a drawn shape rather than a glyph |
| `barCardText` | 78 | what is left |

The rail is reserved whether or not a card has an icon for it, and the majority is reserved whether or not a card has a line to put there. Both reservations *are* the alignment: a card that reclaimed the width it was not using would put its rail at a different x from the card above it, which is the one thing the shared shape exists to prevent. Reserved is not the same as occupied — the majority is the card's budget for information, not a quota it has to meet.

### The icon says what the card is and how it stands

The icon carries two things: **what the card is and how it stands.** Identity alone would be a label, and a label answers nothing — you already know which card is the battery, so a glyph that only says "battery" is spending the rail to tell you what you came in knowing. The icon earns its column by encoding state as well: the battery's fill length and ladder colour, the Bell's colour and its slash.

### A card with nothing to say disappears 

A card leaves the bar when it has nothing relevant to show. `BarWidget.active` drops the widget **and its spacing**, so an up-to-date machine carries no update chrome whatsoever.

Absence is an encoding, not a tidy-up — presence is the whole of Updates' glance layer, and the strongest signal available, because the two states are "a card" and "no card" and nothing else has to be read to tell them apart. But absence says two different things and they are worth keeping apart: *there is nothing to do* (Updates, the Bell) and *there is no answer to give* (the battery on a machine without one, Network while connectivity is unknown). Both render as the same absence. So a card may only use presence as its answer when its question is of the first kind; a card that disappears because it does not know is silent about the fact that it does not know.

### Cards can reveal more

A card answers at a glance and can be asked for more. The asking has two forms, and they must not be confused:

- **Hover sharpens the answer.** The same question at higher resolution, taking no focus and destroying nothing. `Ui/Tooltip.qml`, governed by *Detail is progressively disclosed* below.
- **Click opens somewhere to act on the card's subject.** Not more detail — somewhere to do something about it. The Bell's history is the worked example: it dismisses, clears and toggles do-not-disturb, which is why it holds keyboard focus and why a tooltip could never have been it. A card with nothing to act on gets no click handler, which is why the battery has none.

**The drawer is an experiment.** What a card opens is a drawer: full height, against the bar's inner edge, one fixed width, in the same place whichever card opened it. One position, learned once. It was chosen over anchoring the panel to the card — which moves with the card's place in the bar and with the height of its content, leaving nowhere to learn — and over the centred dialog the installer, power menu and wallpaper picker share, which covers the window being read and is the heaviest gesture available for "show me a bit more".

Nothing is built yet. The notification history is the surface that would move first, and it is the reason this came up: it is anchored top right, from when the bar was on top, while the Bell that opens it now sits at the bottom of a right-hand bar, so clicking the bell throws a panel diagonally across the screen.

Revisit this once a second card has something to reveal. One drawer is not evidence; the question is whether two of them in the same place read as one habit or as a surface that keeps showing unrelated things. If it is the second, anchoring to the card is what to try next. Until then this section describes an intention rather than the shell.

### Breaking the pattern

A card follows the shape unless there is a reason not to, and **a reason not to is written down in that widget's record.** An undocumented deviation cannot be told apart from an oversight, and the next person to look at it — including the one who wrote it — has no way to know whether they are reading a decision or a bug. Two are standing today:

- **Workspaces is not a card** — a grid of pills with no icon and no text, and wrapping it in a rail it would never use would be the standard applied for its own sake. [Record](quickshell/widgets/workspaces.md).
- **The Clock has no icon** — a clock face beside a time answers nothing the time did not already say. That predates the rule above and may not survive it. [Record](quickshell/widgets/clock.md).

## Motion is reserved for attention

Colour, size and shape only work once you are already looking at the bar.
Motion is picked up in peripheral vision.

- **Sustained motion means "this needs a response".** Nothing else may loop, pulse, blink, spin, or drift. Not a loading state, not a nice touch, not an idle flourish.
- **Only one thing moves at a time.** If a second condition could plausibly animate at once, one of them is not actually urgent and should say so another way.
- **Motion stops when the condition clears.** A permanent animation is decoration, and it trains you to ignore the one signal that was supposed to be unignorable. Bind it to the condition, not to the widget's existence.
- **Motion is never the only encoding.** The same state must also be readable from colour and shape, because the animation may be off-screen, occluded, or simply not noticed. Motion escalates a signal; it does not carry one alone.
- **Keep it slow and shallow.** A signal that has to survive peripheral vision needs to be smooth, not sharp. Something around a one-second cycle and a gentle amplitude reads as "attend to this when you can" — a fast or large animation reads as an alarm and becomes hostile within a minute, which is worse than not signalling at all.

## Detail is progressively disclosed

A widget shows one thing at a glance and can be asked for more. That gives it three layers:

1. **The glance layer** is always visible and answers the widget's questions.
2. **The hover layer** answers the *same questions*, more precisely. It is detail on request.
3. **Post action layer** holds everything else.

## Interaction rules

**No interaction is ever required to read a widget.** Interaction is a shortcut to an action, or more information.

Given that:

- **Click performs an action.** On workspaces, the primary question is "which workspace am I on", so click switches to one.
- **Right-click and scroll are secondary and optional.** They may offer a faster path to something, but never the only path.
- **Hover may add detail; it may not carry the answer.** A tooltip is for the thing you occasionally want.

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
