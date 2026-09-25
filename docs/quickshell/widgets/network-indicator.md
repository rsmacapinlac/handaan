# Network indicator

Purpose: Tells the user whether the network they are connected to actually reaches the internet.

Notes:

- There are a states and substates. Connected (but no Internet), Not Connected. Connected (with Internet)
- There are also different network interfaces.
- Connected with Internet is Good, Connected (but no Internet) requires troubleshooting, and Not Connected should be displayed but no action required.
- Connectivity is NetworkManager's answer, on its own endpoint and schedule. This widget starts no probe of its own and changes none of that configuration, so what the globe reports is that check rather than a promise that every site will load.
- Its place is between Updates and Battery. The right section reads Updates, Network, Battery, Clock — machine state together, then the Clock at the end. The Bell used to sit between Battery and Clock; notifications are the island's now.
- Left-click opens `kitty --title 'Network' -e nmtui`, which is where you go to do something about either answer.

Absence:

- A connected network whose internet status is unverified has no card at all, spacing included. This is absence of the *no answer to give* kind rather than the *nothing to do* kind: the widget is silent about being silent, which is the cost of not showing an untested green.
- Its disappearance leaves Battery and the Clock where they were — the row is anchored to the bar's end, so a widget coming and going shifts only what is on its own side. `nmtui` is still there from a terminal while the card is not.

Extra Information:

- Provide the IP address and the connected interface. 
- Underneath it, the transports attached: "Wi-Fi connection", "Wired connection", or both. 
- "Sign-in required" when the connectivity check came back as a captive portal.

## Previewing it

`NetworkPreview` supplies mock state to every monitor without touching any network settings, for looking at the states that are awkward to arrange on purpose. After restarting Quickshell:

```bash
qs -p "$HANDAAN_PATH/default/quickshell" ipc call -- networkPreview show offline wifi
qs -p "$HANDAAN_PATH/default/quickshell" ipc call -- networkPreview show portal wired
qs -p "$HANDAAN_PATH/default/quickshell" ipc call -- networkPreview show live wifi
```

Modes are `online`, `offline` (connected without internet), `portal`, `disconnected`, `unknown` and `live`; transports are `wifi` and `wired`. Each preview expires after ten minutes, the preview is held only in memory, and restarting the bar restores live data.
