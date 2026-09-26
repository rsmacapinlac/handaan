# Network indicator

Purpose: Tells the user whether the network they are connected to actually reaches the internet.

Notes:

- There are a states and substates. Connected (but no Internet), Not Connected. Connected (with Internet)
- There are also different network interfaces.
- Connected with Internet is Good, Connected (but no Internet) requires troubleshooting, and Not Connected should be displayed but no action required.
- Connectivity is NetworkManager's answer, on its own endpoint and schedule. This widget starts no probe of its own and changes none of that configuration, so what the globe reports is that check rather than a promise that every site will load.
- Its place is between Updates and Battery. The right section reads Updates, Network, Battery, Clock — machine state together, then the Clock at the end. The Bell used to sit between Battery and Clock; notifications are the island's now.
- The card carries the transport on its first line, muted -- "Wi-Fi", "Wired" or "Wi-Fi+Wired" -- and the address on its second at full contrast. With both transports up there are two addresses and the card shows neither: picking one would claim it carries the default route, which is not something NetworkManager is asked here. The tooltip lists both.
- Left-click opens `kitty --title 'Network' -e nmtui`, which is where you go to do something about either answer.

Absence:

- A connected network whose internet status is unverified has no card at all, spacing included. This is absence of the *no answer to give* kind rather than the *nothing to do* kind: the widget is silent about being silent, which is the cost of not showing an untested green.
- Its disappearance leaves Battery and the Clock where they were — the row is anchored to the bar's end, so a widget coming and going shifts only what is on its own side. `nmtui` is still there from a terminal while the card is not.

Extra Information:

- Whether the connection reaches the internet, in words: "Internet reachable", "No internet access", "Not connected".
- Under it, the address against the interface carrying it, one line per connected device. That pairing is the thing the card cannot make when both transports are up, which is what earns it the hover layer rather than restating the card.
- "Sign-in required" when the connectivity check came back as a captive portal.

## It holds a share of the motion channel, and stops the wrong way

The globe pulses while the machine is connected and the connectivity check says it is not reaching the internet. That condition qualifies under *Motion is reserved for attention* in [The bar](../../bar.md): it is not the normal state, there is something to do about it -- the click opens `nmtui` -- and it clears itself the moment connectivity comes back. The pulse is escalation rather than the answer: the same state is already in the globe's peach and in the tooltip's "No internet access", so nothing is lost if the motion is never noticed.

**It stops by snapping back, and every other pulse on the bar does not.** Battery, Updates and Workspaces all carry `alwaysRunToEnd: true`, so the leg being drawn finishes and the shape eases to rest; this one sets `onStopped: icon.scale = 1.0` and cuts mid-leg. That is against the table in [The bar](../../bar.md), which asks for the finished leg precisely because recovery is when the widget is most likely to be looked at straight on.

This is recorded as unreconciled, not as a decision. The snap-back is the older of the two: it arrived with the widget, and the motion table was written afterwards, against the three widgets that already agreed. Nothing was weighed and chosen here -- so the next person to touch `modules/Network.qml` should take the shared stop unless they find a reason this widget needs the other one, and replace this section with that reason if they do.

## Previewing it

`NetworkPreview` supplies mock state to every monitor without touching any network settings, for looking at the states that are awkward to arrange on purpose. After restarting Quickshell:

```bash
qs -p "$HANDAAN_PATH/default/quickshell" ipc call -- networkPreview show offline wifi
qs -p "$HANDAAN_PATH/default/quickshell" ipc call -- networkPreview show portal wired
qs -p "$HANDAAN_PATH/default/quickshell" ipc call -- networkPreview show live wifi
```

Modes are `online`, `offline` (connected without internet), `portal`, `disconnected`, `unknown` and `live`; transports are `wifi` and `wired`. Each preview expires after ten minutes, the preview is held only in memory, and restarting the bar restores live data.
