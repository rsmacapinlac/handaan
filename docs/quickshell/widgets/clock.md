# Clock

Two questions: *what time is it?* and *what is today's date?* The implementation reasoning is in the header of `default/quickshell/modules/Clock.qml` — why there are no seconds, why the format is ISO, and why there is no click handler.

## It has no icon

The Clock is a card whose icon rail is empty, on the argument that a clock face beside a time answers nothing the time did not already say. That predates *The icon says what the card is and how it stands*, and whether it survives the rule is open: the icon that would satisfy both halves is a face with real hands, which is also the only icon on the bar that would say exactly what the line beside it says.

The rail is reserved anyway. A card that reclaimed the width it was not using would put its text at a different x from the card above it, which is the one thing the shared shape exists to prevent.
