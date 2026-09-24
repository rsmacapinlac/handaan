# Battery

Purpose: Tells the user whether they need to find a cable, and whether the battery is gaining charge, holding, or running down.

Notes:

- One channel per question, so neither answer has to be read out of the other. Fill length and colour answer the first; the glyph answers the second.
- The glyph sits outside the battery body, so it never competes with the colour that carries severity.
- A green bolt means gaining charge. A muted plug means connected but delivering nothing. The second question used to be "am I on mains", answered by the presence of a bolt, which conflated a charger that is filling the battery with one that is connected and doing nothing. The second is common -- an underpowered supply, a cable that negotiated a low USB-C contract, a charge threshold, a firmware inhibit -- and it looks exactly like charging while the battery quietly drains.
- It does not say *which* of those it is. From here they are indistinguishable, so the widget reports what is observable and leaves the diagnosis to the person.
- Severity only applies on battery. Plugged in at 10% is recovering, not failing, and colouring it red would train the red to be ignored. Warning at 30%, critical at 15%, carried over from the waybar config this replaced so the levels that used to mean something still do.
- The numeral is tinted with the body rather than given a colour of its own, so it joins the existing ladder instead of opening a fourth channel. It is the same answer at higher resolution and should look like it.
- The fill is floored so a nearly-flat battery still draws a sliver. An empty outline reads as "no data", which is a different and much less alarming thing than "no charge".
- It pulses only when critical *and* discharging, on the bar's one cycle for urgency. On mains at 10% it stays still, because the battery is recovering and needs nothing. The pill is also red, so the state survives the motion going unnoticed. This is the fourth holder of a channel the design language rations to one -- see [workspaces](workspaces.md), the [update indicator](update-indicator.md) and the [network indicator](network-indicator.md) -- and the collision it accepts is an urgent workspace pulsing at the same moment, which is not worth demoting either signal to avoid.
- No click handler. There is no obvious action for "the battery is at 40%", and power actions live behind the keyboard rather than in the bar.

Absence:

- A machine with no battery behind its display device -- a desktop, an LXC container -- has no battery card at all, rather than an empty husk. This is absence of the *no answer to give* kind, not the *nothing to do* kind, so it says nothing about the machine beyond the fact that the question does not apply.

Whether there is a numeral:

- On a side bar, yes. On a top bar, no. It is the one thing here decided by room rather than by the question.
- On a top bar the fill length and the colour ladder already answer "do I need to plug in", and a digit beside them is a fourth thing to parse that changes no decision the shape did not already prompt. Dropping it is what buys the width the body spends on fill range, which is what makes the shape answer legible at all.
- A side bar has no such trade to make. The body is 30px in a bar over three times that wide, so the numeral costs width nothing else was going to use. And 40% and 25% are both peach while only one of them sends you looking for a cable.
- So the boundary between the glance and hover layers moves with the bar and the rule does not: hover still only ever sharpens what the shape already said, and nothing below the pointer is required to read the widget either way.

Extra Information:

- The estimate: time remaining on battery, or time until full on mains. Where the numeral is on the bar the estimate leads, because a tooltip opening with the percentage would restate what the pointer is sitting next to; where it is not, the percentage leads and the estimate follows.
- "Fully charged" when it is. "Not charging" for connected-but-gaining-nothing, because the rate and both time estimates sit at 0 and stay there -- falling through to "Estimating" would promise a figure that is never coming, which reads as working and is a lie. "Estimating…" while the draw rate is still settling.
- Rounded to the minute, and the percentage to the whole point. A seconds field on a figure this noisy, or a decimal on a charge level, would be false precision: 68.4% and 68% prompt the same decision.
