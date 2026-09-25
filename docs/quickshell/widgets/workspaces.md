# Workspaces

Two questions: *which workspace is this screen on?* and *which workspace wants attention?* The implementation reasoning is in the header of `default/quickshell/modules/Workspaces.qml` — the three channels each answer is encoded in, why every workspace is labelled, and what a side bar's fixed width cost the encoding.

## It is not a card

Workspaces is a grid of pills with no icon and no text, and wrapping it in a rail it would never use would be the standard applied for its own sake. It is the one widget on the bar that does not take the shape in `Ui/BarCard.qml`.

## It holds the motion channel

An urgent workspace takes the bar's pulse unmodified — the amplitude, tempo and easing are [the design document's](../../quickshell-widgets.md), not this widget's — and stops the moment it stops being urgent, which is *Motion is reserved for attention* applied as written. The pulse is escalation on top of a signal that is already complete without it — the pill is also red, and also wide and labelled — so the widget stays readable if the motion is never noticed.

It is not the only holder of the channel the rule rations to one: the [update indicator](update-indicator.md) and the [network indicator](network-indicator.md) both pulse too, each recording what it traded for it. This one is the cheapest to justify, because its condition is rare and clears itself.

Because the bar is instantiated once per monitor, this widget answers for its own screen: `Hyprland.monitorFor(screen).activeWorkspace`, never the session-wide `Hyprland.focusedWorkspace`, which would make every bar show the same answer.
