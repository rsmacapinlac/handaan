# Notifications

Purpose: Tells the user something happened without taking them away from what they were doing, and keeps it until they have dealt with it.

The decision to draw these in the shell at all, and what that replaced, is [0008](../decisions/adrs/0008-notifications-are-part-of-the-desktop-shell.md). The bar indicator is the island's backlog badge, in [The island](README.md); the widget it replaced kept its argument in [notification bell](../quickshell/widgets/notification-bell.md), which is retired. This is what the surfaces themselves have to do.

Three questions, and each has its own surface:

1. *Did something just happen?* — the popup.
2. *What have I not dealt with?* — the history, and the island's backlog badge.
3. *Will I be told?* — do-not-disturb.

## The popup

Purpose: Says that something happened, now, where the user is looking.

Notes:

- On the focused monitor. A popup on the other screen is a popup missed.
- Top centre, below the bar and under the island. One place, learned once. It was top right until the island took notifications; announcing the same thing in the centre and on the far side of the screen would have been two unrelated places.
- At most four at once. Past that the screen is being used as a queue, and a queue is what the history is for.
- Each popup counts down independently from its arrival, for two seconds, including critical notifications. Sender timeouts are ignored.
- Another notification arriving or closing does not restart existing countdowns. Hover holds only that popup; leaving gives it at least 1.5 seconds before it disappears.
- Nothing pops up over the lock screen, and nothing replays on unlock.
- It takes no keyboard focus and covers no more of the screen than its own cards.
- Arriving slides, leaving fades. Both are transitions, over before you look. Nothing here loops; kept notifications remain available in the island.
- Closing a popup means "off my screen", not "dealt with". It stays in the history.

Absence:

- No popup is the normal state, and says nothing. This is the *nothing to say* kind.

## The history

Purpose: Tells the user what has arrived that they have not dealt with, and lets them deal with it.

Notes:

- Summoned: `Super+Shift+N` or `handaan notifications`. Dismissed like the shell's other dialogs -- Escape, or a click off the panel. Clicking the island expands its own copy of the same list, which is the ordinary way in; this panel is the keyboard one.
- Top right, under the bar. It no longer sits where the popups do -- they moved to the centre with the island -- so the reading it used to get, of the ones already gone coming back, belongs to the island's expansion now.
- Every card is the popup it was, with its actions still live while the notification is kept.
- Closing a card here dismisses it for good. That is the difference from a popup's close.
- Opening it is reading it. Everything is marked seen, and there is no per-card read state to manage.
- Read is not dealt with. The badge stays until a card is closed or the history cleared.
- A notification that asks not to be kept is not kept. It is a popup or it is nothing.
- A notification its own app closes -- a message read on another device -- leaves both the screen and the history.
- Capped at 100. Past that the oldest are expired rather than dropped, so their senders are told.
- Held in memory only. A notification carries message previews and senders; none of it is written to disk, and a restart starts empty.

Absence:

- Nothing kept means no panel worth opening. The island's badge is what says so -- see [The island](README.md).

## The card

Purpose: Says who is telling the user what, and what they can do about it.

Notes:

- The same card as a popup and in the history. One notification should not look like two different things depending on where it is read.
- In reading order: who sent it and when, what it says, what you can do about it.
- Critical is the one state drawn loudly, as a critical border, because it is the one that stays until acted on.
- The body is the protocol's markup subset -- bold, italic, underline.
- Images are stripped. An `<img>` in a body can name a remote URL, and fetching it would tell the sender the notification was displayed.
- Action buttons work wherever the card is, for as long as the notification is kept.

## Do-not-disturb

Purpose: Tells the user whether they are going to be interrupted, and lets them stop being.

Notes:

- Holds popups, not notifications. They still arrive, still land in the history, and the badge still appears.
- Critical still pops up. Do-not-disturb is not a mute switch for things that matter.
- Remembered across a restart, since forgetting it at login would undo the one thing it is for. It is the only notification state written to disk.
- The badge says it is on, by its shape: a slashed bell. An empty island cannot say it, which is why the badge stays up while it is.

## What is deliberately not here

- **No per-app rules, filters or sounds.** Nothing has wanted one yet, and each is a configuration surface that has to live somewhere and be explained.
- **No grouping or stacking by app.** Four popups is the cap; past that the history is the answer.
- **No history on disk.** See above -- the content is the reason.
- **No second notification daemon as a fallback.** Only one program can own the name. [0008](../decisions/adrs/0008-notifications-are-part-of-the-desktop-shell.md) has what that costs.
