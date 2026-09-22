# Quickshell Widget Design

This document governs the design language of the bar widget.

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

Cards stack. The bar runs vertically by default, so a card is read down the bar with its neighbours — which is where the shared shape earns itself: five cards whose text all begins at the same x read as one column, and five centred on their own differing widths read as five widgets. The same card lays out as a row on a top bar, icon then the lines beside each other, so a widget's content is declared once rather than twice. One visible consequence there: the accessory follows the icon instead of preceding it, so the battery reads body-then-bolt rather than bolt-then-body. The card puts the icon first, always.

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

The icon carries two things: **what the card is, and how that thing stands right now.** Identity alone would be a label, and a label answers nothing — you already know which card is the battery, so a glyph that only says "battery" is spending the rail to tell you what you came in knowing. The icon earns its column by encoding state as well: the battery's fill length and ladder colour, the Bell's colour and its slash.

That is a change, and not every card meets it yet. Network and Updates encode state in colour alone, which is the weakest form of the rule — their shape is identical across every state they distinguish, so the encoding holds only as long as the hues stay apart. The Clock has no icon at all, and is an exception below. The battery is the one card that meets the rule in full, and needs revisiting for the opposite reason: fill length, ladder colour and the `68%` numeral are three encodings of one answer, and the clause that used to license a refinement as not-a-new-state is no longer in this document.

### Two lines is a ceiling, not a quota

A card with nothing worth saying is an icon and an empty information column, and that is the correct shape for it: Updates, Network and the Bell are all icon-only. What belongs on the glance layer is settled by the rules above, and having somewhere to put a line is not a reason to find one. This is the rule the card exists to make visible — **room is never an argument for a new answer.** It is only ever an argument for stopping the hiding of one the widget already gives, which is *Detail is progressively disclosed*, below.

The ceiling is enforced rather than trusted. There are two line properties and no third; each is capped at `barCardText` and elides. What that prevents is a widget quietly growing a third line, or a line too long for its column, and widening the bar for every other card at once — it takes its thickness from the widest thing in it, so one card's greed is charged to all of them. For scale, 78px holds a ten-character date at `fontSizeSmall` with 11px to spare, and about nine characters at `fontSize`. The cap applies down a vertical bar; a card on a top bar is as wide as it needs to be.

The lines are named by position rather than by rank, because which one carries the answer differs by card: the battery leads with its figure, the clock leads with its date and puts the time underneath. So the card takes a colour and a size per line instead of ranking them itself. Beside line one there is one more slot, the **accessory**: a component, for the one thing a string cannot carry — a glyph needing a colour of its own. The battery's bolt is green while it is gaining charge, next to a numeral on the severity ladder, and one `Text` cannot be both.

### A card with nothing to say disappears 

A card leaves the bar when it has nothing relevant to show. `BarWidget.active` drops the widget **and its spacing**, so an up-to-date machine carries no update chrome whatsoever.

Absence is an encoding, not a tidy-up — presence is the whole of Updates' glance layer, and the strongest signal available, because the two states are "a card" and "no card" and nothing else has to be read to tell them apart. But absence says two different things and they are worth keeping apart: *there is nothing to do* (Updates, the Bell) and *there is no answer to give* (the battery on a machine without one, Network while connectivity is unknown). Both render as the same absence. So a card may only use presence as its answer when its question is of the first kind; a card that disappears because it does not know is silent about the fact that it does not know.

### Cards can reveal more

A card answers at a glance and can be asked for more. The asking has two forms and they must not be confused:

- **Hover sharpens the answer.** The same question at higher resolution, taking no focus and destroying nothing. `Ui/Tooltip.qml`, governed by *Detail is progressively disclosed* below.
- **Click opens somewhere to act on the card's subject.** Not more detail — somewhere to do something about it. The Bell's history is the worked example: it dismisses, clears and toggles do-not-disturb, which is why it holds keyboard focus and why a tooltip could never have been it. A card with nothing to act on gets no click handler, which is why the battery has none.

**The drawer is an experiment.** What a card opens is a drawer: full height, against the bar's inner edge, one fixed width, in the same place whichever card opened it. One position, learned once. It was chosen over anchoring the panel to the card — which moves with the card's place in the bar and with the height of its content, leaving nowhere to learn — and over the centred dialog the installer, power menu and wallpaper picker share, which covers the window being read and is the heaviest gesture available for "show me a bit more".

Nothing is built yet. The notification history is the surface that would move first, and it is the reason this came up: it is anchored top right, from when the bar was on top, while the Bell that opens it now sits at the bottom of a right-hand bar, so clicking the bell throws a panel diagonally across the screen.

Revisit this once a second card has something to reveal. One drawer is not evidence; the question is whether two of them in the same place read as one habit or as a surface that keeps showing unrelated things. If it is the second, anchoring to the card is what to try next. Until then this section describes an intention rather than the shell.

### Breaking the pattern

A card follows the shape unless there is a reason not to, and **a reason not to is written down here.** An undocumented deviation cannot be told apart from an oversight, and the next person to look at it — including the one who wrote it — has no way to know whether they are reading a decision or a bug.

**Workspaces is not a card.** It is a grid of pills with no icon and no text, and wrapping it in a rail it would never use would be the standard applied for its own sake.

**The Clock has no icon**, on the argument that a clock face beside a time answers nothing the time did not already say. That predates the rule above, and whether it survives it is open: the icon that would satisfy both halves is a face with real hands, which is also the only icon on the bar that would say exactly what the line beside it says.

## Motion is reserved for attention

Colour, size and shape only work once you are already looking at the bar.
**Motion is the only channel that reaches you when you are not** — it is picked
up in peripheral vision, which is exactly the case "something needs you" has to
survive. That makes it the most valuable signal available, and the easiest to
destroy.

It is destroyed by spending it. If two things in the bar are moving, neither one
is urgent — they are both just animation, and the eye learns to discard them.
So:

- **Sustained motion means "this needs a response".** Nothing else may loop,
  pulse, blink, spin, or drift. Not a loading state, not a nice touch, not an
  idle flourish.
- **At most one thing moves at a time.** If a second condition could plausibly
  animate at once, one of them is not actually urgent and should say so another
  way.
- **Motion stops when the condition clears.** A permanent animation is
  decoration, and it trains you to ignore the one signal that was supposed to be
  unignorable. Bind it to the condition, not to the widget's existence.
- **Motion is never the only encoding.** The same state must also be readable
  from colour and shape, because the animation may be off-screen, occluded, or
  simply not noticed. Motion escalates a signal; it does not carry one alone.
- **Keep it slow and shallow.** A signal that has to survive peripheral vision
  needs to be smooth, not sharp. Something around a one-second cycle and a
  gentle amplitude reads as "attend to this when you can" — a fast or large
  animation reads as an alarm and becomes hostile within a minute, which is
  worse than not signalling at all.

### Transitions are not motion

State changes settling over ~120–240ms are a different thing and are not
governed by the rule above. Their job is to make a change *legible as a change*
— the eye follows a pill growing into place and knows what happened, where an
instant swap just looks like a different bar. They are bounded, caused by an
event, and over before you look.

The distinction is sustained versus transitional. A transition is triggered and
ends; motion loops until the condition clears. Only the looping kind is the
attention channel and only it is rationed.

The worked example is the workspace widget: an urgent workspace pulses on about
a 1.2s cycle at 12% scale, and stops the moment it stops being urgent. It is
also red, and also a wide labelled pill, so the pulse is escalation on top of an
already-complete signal rather than the signal itself. The battery uses the same
cycle and amplitude for critical-and-discharging, so the bar has one vocabulary
for urgency rather than several.

**The update indicator is a deliberate exception, and it is worth being honest
about which rule it breaks.** It carries a three-level colour ladder and pulses
only at the top of it, which is the battery's discipline exactly -- motion at
the severe end, not whenever the widget is drawn. What it does not have is the
battery's other property: its top level is *package updates available*, and on
Arch that is true most days and never clears on its own. So the pulse is bound
to a condition that recurs rather than one that resolves, which is the shape
this section calls decoration.

That was chosen with the alternative in view. Ranking by rarity instead --
pending migrations at the top, which are unusual and self-clearing -- would have
made the better signal, and ranking by consequence was preferred anyway, because
an unpatched system is the more serious fact about a machine. Two things follow.
It is the third holder of a channel this section rations to one, and it collides
worst exactly where it matters: at or below 15% the battery is also `critical`
red on the same 620ms cycle, so a nearly-flat battery and a backlog of packages
render as the same colour at the same rhythm. And if the channel starts feeling
like noise, this is the pulse to remove first, because it is the one carrying
the least.

### Notification bell

The bell asks two questions: "is anything waiting for me, and how much does it matter?" and "am I going to be told when something new arrives?" Like Updates, presence is the first answer: the bell is on the bar while anything is kept in history and gone, spacing and all, when nothing is. Waiting means kept rather than unseen. Opening the history marks everything seen, and a bell that vanished the moment you looked would hide what you have not dealt with; dismissing it or clearing the history is what takes the bell away.

Colour is how much it matters: the most urgent notification kept, not the newest, so a chatty app cannot bury a critical one. Critical is `Theme.critical`, normal is `Theme.active`, and low is `Theme.barTextMuted` grey. Peach is deliberately not used, because it is Network's and Battery's warning and a normal notification is not a warning. Shape is the second question: a slashed bell while do-not-disturb is on. Do-not-disturb holds the bell up by itself, grey when nothing is kept, because being quiet is the one state you must not forget you are in; turned off with nothing kept, the bell goes. There is no count on the glance layer; one notification and six ask the same thing of you. Hover gives the number, split by urgency when it is mixed, and how many are unseen.

It does not move, deliberately. A notification that needs a response now is critical, and critical already stays on screen until dismissed, so a pulse here would be another holder of the attention channel saying less than the popup does. Click opens the history, which is the obvious action for both questions and destroys nothing.

### Network indicator

The network widget asks "does my connected network have internet access?" A
bare globe, sized like Updates, is green (`Theme.good`) with internet access
and peach (`Theme.warning`) without it. The peach state pulses at the same
100–112% scale and 620ms per leg as Battery and Updates. It stops and resets
when internet returns or the connection drops. This deliberately adds another
holder of the motion channel, and uses warning rather than critical colour.
Both states use the same shape: colour and motion distinguish them, accepting
the limitation that without motion their distinction depends on colour.

Disconnected is a steady gray globe (`Theme.barTextMuted`) with a "Not
connected" tooltip; clicking still opens `nmtui`. Connected networks with
unknown internet status are hidden, including their spacing. The
widget sits between Updates and Battery, so its disappearance leaves Battery,
the Bell and Clock in place. The right section reads Updates, Network, Battery,
Bell, Clock: machine state together, then the Bell beside the Clock, next to
the corner where notifications open. The Bell comes and goes too, and keeps
that place anyway: the row is anchored right, so its arrival shifts the
widgets to its left and never the Clock. Hover says "Internet reachable" or "No internet access",
with "Wi-Fi connection", "Wired connection", or both underneath, plus
"Sign-in required" for a captive portal. This is an explicit extension of
the hover rule: transport detail is available on hover while the globe keeps
the glance layer focused on internet access. Both connected transports are
listed without implying which carries the default route. Left-click opens
`kitty --title 'Network' -e nmtui`; scroll and right-click do nothing. When the
widget is hidden, `nmtui` remains available from a terminal.

Declarative bindings read the process-wide `Quickshell.Networking` service.
NetworkManager owns connectivity checking, using its configured endpoint and
schedule; this widget neither starts extra probes nor changes that config.
Its result describes that check, not a guarantee that every website works.
Disabled or unavailable checks are treated as unknown, rather than accepting
an untested green state. A connected device with `None`, `Limited`, or
`Portal` connectivity gets peach; `Full` gets green. No connected device means
gray regardless of a previous connectivity result.

The implementation lives under `default/quickshell/`, so both fresh and
existing installations read it directly. It requires Quickshell's Networking
module and the existing NetworkManager and Kitty packages, with no new seed
or migration. Restart `quickshell.service` to apply it to an existing session.

For visual review, `NetworkPreview` can supply mock state to every monitor
without changing any network settings. After restarting Quickshell, run:

```bash
qs -p "$HANDAAN_PATH/default/quickshell" ipc call -- networkPreview show offline wifi
qs -p "$HANDAAN_PATH/default/quickshell" ipc call -- networkPreview show portal wired
qs -p "$HANDAAN_PATH/default/quickshell" ipc call -- networkPreview show live wifi
```

Modes are `online`, `offline` (connected without internet), `portal`,
`disconnected`, `unknown`, and `live`; transports are `wifi` and `wired`.
Each preview expires after ten minutes, and restarting the bar restores live
data. The preview is held only in memory and leaves tooltip styling intact.

## Detail is progressively disclosed

A widget shows one thing at a glance and can be asked for more. That gives it
three layers, and the discipline is entirely in what is allowed to live in
each:

1. **The glance layer** is always visible and answers the widget's questions.
   It is the widget. Everything in the sections above governs it.
2. **The hover layer** answers the *same questions*, more precisely. It is
   detail on request.
3. **The terminal** holds everything else, and is not in the bar at all.

The load-bearing rule is the one binding the second layer to the first:

**Hover may sharpen an answer the widget already gave. It may not introduce a
question the widget does not claim to answer.** The distinction is the question,
not the datum — a tooltip is free to derive, compute, or reformat, as long as
what comes out is the same question at higher resolution. The moment hovering
teaches you something the glance layer could not have told you, one of two
things is true: either that information belongs in the glance layer and is
missing from it, or it fails the test in the first section and does not belong
in the bar at all. Neither is fixed by leaving it in a tooltip.

### The cover test

Cover the tooltip and use the widget for a day.

If it still answers its questions, the disclosure is layered correctly. If you
find yourself hovering to find out where you stand, the tooltip was carrying
the answer, and the widget underneath it is broken — the tooltip was hiding
that, which is the failure worth catching, because a broken widget with a good
tooltip feels fine right up until the pointer is somewhere else.

### What the hover layer owes you

- **It is never required.** No interaction is the reading path; this is the
  detail path. This is just the rule from the first section, restated where it
  is easiest to break.
- **It waits.** A tooltip that fires instantly strobes every widget you sweep
  the pointer past on the way somewhere else. Something around 400ms means it
  only appears when you actually stopped on it.
- **It never takes focus.** A panel that steals the keyboard from the window
  underneath it is a bug on a keyboard-driven desktop, whatever it is showing.
- **It leaves when you do**, and it stays inside the screen. Bar widgets sit at
  the edges, so a tooltip centred on one will hang off the display unless it is
  told to slide back inside.
- **It says why a value is missing** rather than going blank — and says the
  *right* why. A tooltip with a gap in it reads as broken; one that says it is
  still estimating reads as working, which is worse than the gap when no
  estimate is ever coming. "Not ready yet" and "there will never be one" are
  different states, and a placeholder that conflates them is a lie that looks
  healthy. The battery widget hit this the first time it was plugged in: the
  supply was too weak to charge at all, so the rate and both time estimates sat
  at zero indefinitely, and a tooltip written to treat zero as "still working
  it out" promised a figure that was never going to arrive. Note that the
  widget cannot tell *why* — a charge threshold, a firmware inhibit and an
  underpowered charger are identical from where it sits — which is the second
  half of the rule: say the observable fact, and resist explaining a cause you
  are guessing at.
- **Nothing it does is destructive.** Hover fires by accident, every time.

### The worked example

The battery widget's glance layer is fill length, the colour ladder, and the
bolt: how much is left, whether that is a problem, and whether it is going up
or down. Its hover layer is `68%` and `5h 13m remaining`.

Note what that split does with the numeral. The percentage was deliberately
kept *out* of the glance layer — fill length and colour already answer "do I
need to plug in", and a digit beside them is a fourth thing to parse that
changes no decision the shape did not already prompt. But 40% and 25% are both
peach, and only one of them sends you looking for a cable. That is a precision
question, and precision is exactly what the second layer is for.

The time estimate is the same question again, in the unit you actually act on.
It is derived from a fact the glance layer never shows — the current draw rate
— and it is still legal, because it resolves "do I need to plug in?" rather
than asking something new. That is the rule doing real work: it is about the
question, not the datum.

**Where the boundary between the two layers sits is not fixed, and the side bar
is what showed it.** A vertical bar gives the battery a 78px text column
beside its icon, so the numeral there costs width nothing else was going to
spend — and the argument that kept it off a 34px top bar was, in the half that
was about width, an argument about a bar that no longer exists. So on a side
bar the percentage is drawn on the card, and the tooltip gives up restating it
and leads with the estimate instead. On a top bar nothing changed.

Note what did *not* move. The question is the same on both bars, and so is the
ranking: shape first, precision second, and the shape alone still answers it.
Only the line between the layers moved, and it moved because the room did.
That is the whole of what extra space licenses — **it is never a licence to add
a question the widget does not answer, only a licence to stop hiding an answer
it already gives.** The counts on Updates and the Bell stayed off their cards
for exactly this reason: two updates and forty prompt the same act, which a
wider bar does not change.

## Interaction rules

**No interaction is ever required to read a widget.** Interaction is a shortcut
to an action, never the way information is revealed. A widget whose answer is
only visible on hover or click has failed the glance test by definition.

Given that:

- **Click performs the obvious action for the primary question.** On workspaces,
  the primary question is "which workspace am I on", so click switches to one.
  If there is no obvious action, the widget does not need a click handler.
- **Right-click and scroll are secondary and optional.** They may offer a faster
  path to something, but never the only path — the same thing must be reachable
  without them. Prefer the terminal-first tool that already does the job over
  building a second interface into the bar.
- **Hover may add detail; it may not carry the answer.** A tooltip is for the
  thing you occasionally want, not the thing the widget exists to tell you. See
  "Detail is progressively disclosed" above for what the hover layer owes you.
- **Nothing destructive on scroll or hover.** These fire by accident. Anything
  that logs out, disconnects, kills a process, or cannot be undone belongs
  behind a deliberate click, and usually behind a confirmation.

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
