# Widget records

One file per bar widget, holding what is true about that widget rather than what is true about widgets in general. The design language every one of them answers to is [Quickshell widget design](../../quickshell-widgets.md) — read that first; a record here states the questions its widget answers, how it encodes them, and where it departs from that document and why.

- [Clock](clock.md) — a card with no icon.
- [Network indicator](network-indicator.md) — internet access, and the exceptions it takes to the motion rule.
- [Notification bell](notification-bell.md) — what is kept and whether you will be told.
- [Update indicator](update-indicator.md) — the deliberate exception to *Motion is reserved for attention*.
- [Workspaces](workspaces.md) — the one widget that is not a card.

The battery has no file here yet. Its design reasoning is in the header of `default/quickshell/modules/Battery.qml`, which is the fullest of them — what the glance layer carries, what was deliberately left on hover, and why the boundary between the two moved when the bar did.

These records do not replace the module header comment. Each widget still opens with the questions it answers in its own `.qml`, which is where the implementation reasoning lives — see [code style](../../code-style.md). A record here is the design side of the same widget, kept out of the design document so that document stays about the rules.
