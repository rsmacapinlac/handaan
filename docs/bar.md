# The bar

The bar is one surface in three sections.

Each section has its own standard, because a rule that holds for one does not automatically hold for the others:

- **Workspaces** — [record](quickshell/widgets/workspaces.md).
- **Island** — [The island](island/README.md); nothing is built yet.
- **Widgets** — [Widgets](widgets.md), the card and everything that follows from it.

## The three sections

The bar is one surface, and it is not one design language.

| section | what it holds | the kind of question it answers |
|---|---|---|
| **workspaces** | a grid of pills | *where am I, and what wants me* |
| **island** | what you can act on | *what is going on, and what can I do about it* |
| **widgets** | cards | *what is the state of this machine* |

The split is by what you do with each, which is why one design language could not cover all three. A widget is a fixed question in a fixed place, and you read it: the battery is always the battery, and you learn where it is once. The island is the opposite on both counts — you use it rather than read it, and what is in it changes between glances, so it cannot earn its place the way a card does. Workspaces is neither: it is one question, but its answer is a shape rather than a value, and a rail and a text column would be a standard applied for its own sake.

**The sections share the rules below and nothing else.** Glance-ability, the motion channel and what interaction may do are the bar's, not a section's. The card, the rail, the text budget and the hover layer are the widgets section's alone -- only cards have a tooltip.

## The principle: everything on the bar should be glance-able

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

## Motion is reserved for attention

Colour, size and shape only work once you are already looking at the bar.
Motion is picked up in peripheral vision.

- **Sustained motion means "this needs a response".** Nothing else may loop, pulse, blink, spin, or drift. Not a loading state, not a nice touch, not an idle flourish.
- **Only one thing moves at a time.** If a second condition could plausibly animate at once, one of them is not actually urgent and should say so another way.
- **Motion stops when the condition clears.** A permanent animation is decoration, and it trains you to ignore the one signal that was supposed to be unignorable. Bind it to the condition, not to the widget's existence.
- **Motion is never the only encoding.** The same state must also be readable from colour and shape, because the animation may be off-screen, occluded, or simply not noticed. Motion escalates a signal; it does not carry one alone.
- **Keep it slow and shallow.** A signal that has to survive peripheral vision needs to be smooth, not sharp. Something around a one-second cycle and a gentle amplitude reads as "attend to this when you can" — a fast or large animation reads as an alarm and becomes hostile within a minute, which is worse than not signalling at all.

### There is one pulse, and a section borrows it

The rules above ration motion to one meaning, so the bar carries one animation to say it with. Whatever has earned the channel takes the pulse as it stands; it does not design its own. Two rhythms on one bar would read as two kinds of urgency, and the previous section has already said there is only one.

| | value | why this number |
|---|---|---|
| amplitude | `1.12` | Twelve per cent is enough to catch the eye beside a still column at the size a bar widget actually draws, and little enough that the card does not appear to change size when you look straight at it. |
| leg | `620ms` | A cycle a shade over a second, which is the "attend to this when you can" tempo above rather than an alarm. |
| easing | `Easing.InOutSine` | Slowest at both ends, so the motion has no edge to it. Linear reads as mechanical and sharp. |
| loops | `Animation.Infinite`, `running` bound to the condition | Bound to the condition and not to the widget, so it stops on its own. |
| stopping | `alwaysRunToEnd: true` | The leg being drawn finishes, so the shape eases back to rest. |

**Stop by finishing the leg, not by snapping back.** Recovery is the moment the widget is most likely to be looked at directly, and cutting the animation mid-scale puts a jump there — the one sharp movement in a signal whose whole argument is that it is smooth. It also costs nothing: the condition has cleared, so the extra half-second is the animation getting out of the way rather than a delay in saying anything.

**One element pulses, not the card.** The battery scales the graphic in the rail while the numeral beside it holds still, so the motion reads as one thing moving rather than the card breathing. A whole card in motion also disturbs the column it sits in, which is the alignment *Every widget is a card* exists to hold.

These numbers are literals in each widget that pulses — `modules/Battery.qml`, `modules/Network.qml`, `modules/Updates.qml` and `modules/Workspaces.qml` — rather than tokens in `Commons/Style.qml`, so nothing but this table keeps them in step. Two of them name the amplitude as a `pulseScale` property because they also size a glyph from it; the other two write it inline.

## Interaction rules

**No interaction is ever required to read a widget.** Interaction is a shortcut to an action, or more information.

Given that:

- **Click performs an action.** On workspaces, the primary question is "which workspace am I on", so click switches to one.
- **Right-click and scroll are secondary and optional.** They may offer a faster path to something, but never the only path.
- **Hover may add detail; it may not carry the answer.** A tooltip is for the thing you occasionally want.

## The workspaces section

Workspaces is a grid of pills with no icon and no text, and wrapping it in a rail it would never use would be the standard applied for its own sake. It is not a card and is not trying to be one: the card is the widgets section's shape, and this is not that section. [Record](quickshell/widgets/workspaces.md).

It holds one end of the motion channel, on an urgent workspace, which is the cheapest holder to justify because its condition is rare and clears itself.

## The island section

The centre of the bar, and the only section you act in rather than read. Its standard is [The island](island/README.md): what may occupy it, its two states, and the decisions still open. Nothing is built there yet.

## The widgets section

The right of the bar, and the only section built from cards. Its standard is [Widgets](widgets.md): the card's shape, the rail and text budget, what absence means, and how a card reveals more. Nothing in that document applies to the other two sections.
