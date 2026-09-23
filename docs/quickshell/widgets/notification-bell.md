# Notification bell

Two questions: *is anything waiting for me, and how much does it matter?* and *am I going to be told when something new arrives?* The implementation reasoning is in the header of `default/quickshell/modules/Bell.qml`.

Like Updates, presence is the first answer: the bell is on the bar while anything is kept in history and gone, spacing and all, when nothing is. Waiting means kept rather than unseen. Opening the history marks everything seen, and a bell that vanished the moment you looked would hide what you have not dealt with; dismissing it or clearing the history is what takes the bell away.

Colour is how much it matters: the most urgent notification kept, not the newest, so a chatty app cannot bury a critical one. Critical is `Theme.critical`, normal is `Theme.active`, and low is `Theme.barTextMuted` grey. Peach is deliberately not used, because it is Network's and Battery's warning and a normal notification is not a warning. Shape is the second question: a slashed bell while do-not-disturb is on. Do-not-disturb holds the bell up by itself, grey when nothing is kept, because being quiet is the one state you must not forget you are in; turned off with nothing kept, the bell goes. There is no count on the glance layer; one notification and six ask the same thing of you. Hover gives the number, split by urgency when it is mixed, and how many are unseen.

It does not move, deliberately. A notification that needs a response now is critical, and critical already stays on screen until dismissed, so a pulse here would be another holder of the attention channel saying less than the popup does. Click opens the history, which is the obvious action for both questions and destroys nothing.
