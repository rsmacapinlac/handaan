# Battery

Purpose: Tells the user whether they need to find a cable, and whether the battery is gaining charge, holding, or running down.

Notes:

- The battery section should have states: Charging, plugged-in, fully charged and discharging.
- In addition to states, the widget should also signal when a user needs to take action (Warning 30% or Critical 15%)
- Icon should tell you what is the state of the battery. 
- Icon's color should also show state (eg. Green is charging, gray not charging)
- Icon movement / motion should indicate when a user needs to take action.
- Numerical should give you a precise reading of the % charge.
- Secondary information should tell you what to do. (ie. Warning 30% and Critical 15% should tell the user to plug in). If a user has no action, then there shouldn't be any secondary information displayed.

Absence:

- A machine with no battery behind its display device -- a desktop, an LXC container -- has no battery card at all. Do not display this widget.

Extra Information:

- The estimate: time remaining on battery, or time until full on mains. Where the numeral is on the bar the estimate leads, because a tooltip opening with the percentage would restate what the pointer is sitting next to; where it is not, the percentage leads and the estimate follows.
- "Fully charged" when it is. "Not charging" for connected-but-gaining-nothing, because the rate and both time estimates sit at 0 and stay there -- falling through to "Estimating" would promise a figure that is never coming, which reads as working and is a lie. "Estimating…" while the draw rate is still settling.
- Rounded to the minute, and the percentage to the whole point. A seconds field on a figure this noisy, or a decimal on a charge level, would be false precision: 68.4% and 68% prompt the same decision.
