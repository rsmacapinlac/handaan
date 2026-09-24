# Notification bell

Purpose: Tells the user whether anything is waiting for them and how much it matters, and whether they will be told when something new arrives.

Notes:

- Presence is the first answer. The bell is on the bar while anything is kept in history, and off it when nothing is.
- Waiting means kept, not unseen. Opening the history marks everything seen, and a bell that vanished the moment you looked would hide what you have not dealt with behind a door you have to remember exists. Dismissing a notification, or clearing the history, is what takes the bell away.
- Colour is how much it matters. It is taken from the most urgent notification kept rather than the newest, so a chatty app cannot bury a critical one. Critical is `Theme.critical`, normal is `Theme.active`, low is `Theme.barTextMuted`.
- Peach is deliberately not used. It is Network's and Battery's warning, and a normal notification is not a warning.
- Shape answers the second question: a slashed bell while do-not-disturb is on.
- Do-not-disturb holds the bell up by itself, grey, when nothing is kept. Being quiet is the one state you must not forget you are in, and an empty bar cannot say it. Turned off with nothing kept, the bell goes.
- No count on the glance layer. One notification and six ask the same thing of you.
- It does not move, deliberately. A notification that needs a response now is critical, and critical already stays on screen until dismissed, so a pulse here would be another holder of the attention channel saying less than the popup already does.
- Click opens the history. It is the obvious action for both questions and it destroys nothing.

Absence:

- Nothing kept and do-not-disturb off means no bell at all, and its spacing goes with it. This is absence of the *nothing to do* kind rather than the *no answer to give* kind, so it is a real answer: a machine with no notification chrome on it has nothing waiting.

Extra Information:

- How many are kept, split by urgency when the kept notifications are of more than one, and how many of them you have not seen yet.
- While do-not-disturb is on, that only critical notifications will pop up.
