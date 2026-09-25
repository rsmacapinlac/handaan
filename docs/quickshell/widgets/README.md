# Widget records

One file per bar widget, holding what is true about that widget rather than what is true about widgets in general. The design language every one of them answers to is [Widgets](../../widgets.md), over the rules in [The bar](../../bar.md) — read those first; a record here states the questions its widget answers, how it encodes them, and where it departs from that document and why.

- [Battery](battery.md) — whether you need a cable, and whether it is gaining or draining.
- [Clock](clock.md) — the date, the time and the day, with the month on hover.
- [Network indicator](network-indicator.md) — internet access, and the exceptions it takes to the motion rule.
- [Notification bell](notification-bell.md) — retired; its job is the [island](../../island/README.md)'s now, and the record is kept for the argument.
- [Update indicator](update-indicator.md) — the deliberate exception to *Motion is reserved for attention*.
- [Workspaces](workspaces.md) — the one widget that is not a card.

These records do not replace the module header comment. Each widget still opens with the questions it answers in its own `.qml`, which is where the implementation reasoning lives — see [code style](../../code-style.md). A record here is the design side of the same widget, kept out of the design document so that document stays about the rules.
