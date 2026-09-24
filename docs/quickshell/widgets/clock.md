# Clock

Purpose: Tells the user what date, time and day it is.

Notes:

- Its position is reserved on the bar. The clock is anchored to the bar's end.
- No seconds as that creates movement. Movement is reserved for notifying the user.
- Use the SystemClock rather than a timer.
- Two lines. Weekday and date on the first, muted; the time on the second, at full contrast. 
- The icon is identity only. 
- ISO date ordering. It sorts, it is unambiguous about day-versus-month, and it reads the same way as everything else in a terminal-first setup.
- The year is not on the bar. The weekday beside a full ISO date needs fourteen monospace characters and the card's text column holds eleven, so the year gives way to the day the purpose asks for. It is on hover.
- No click handler. There is no action behind "it is Wednesday", and a calendar popup would be a second interface for something `cal` already does.

Extra Information:

- Current month's calendar, on hover, under the full date in words. Monday first to match the ISO ordering, today in brackets. It answers the same question the bar does -- what is today's date -- with the week and the month it sits in.
