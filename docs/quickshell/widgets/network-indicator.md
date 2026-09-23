# Network indicator

One question: *does my connected network have internet access?* The implementation reasoning is in the header of `default/quickshell/modules/Network.qml`.

## What it shows

A bare globe, sized like Updates, is green (`Theme.good`) with internet access and peach (`Theme.warning`) without it. The peach state pulses at the same 100–112% scale and 620ms per leg as Battery and Updates. It stops and resets when internet returns or the connection drops. This deliberately adds another holder of the motion channel, and uses warning rather than critical colour. Both states use the same shape: colour and motion distinguish them, accepting the limitation that without motion their distinction depends on colour.

Disconnected is a steady gray globe (`Theme.barTextMuted`) with a "Not connected" tooltip; clicking still opens `nmtui`. Connected networks with unknown internet status are hidden, including their spacing. The widget sits between Updates and Battery, so its disappearance leaves Battery, the Bell and Clock in place. The right section reads Updates, Network, Battery, Bell, Clock: machine state together, then the Bell beside the Clock, next to the corner where notifications open. The Bell comes and goes too, and keeps that place anyway: the row is anchored right, so its arrival shifts the widgets to its left and never the Clock. Hover says "Internet reachable" or "No internet access", with "Wi-Fi connection", "Wired connection", or both underneath, plus "Sign-in required" for a captive portal. This is an explicit extension of the hover rule: transport detail is available on hover while the globe keeps the glance layer focused on internet access. Both connected transports are listed without implying which carries the default route. Left-click opens `kitty --title 'Network' -e nmtui`; scroll and right-click do nothing. When the widget is hidden, `nmtui` remains available from a terminal.

## Where the answer comes from

Declarative bindings read the process-wide `Quickshell.Networking` service. NetworkManager owns connectivity checking, using its configured endpoint and schedule; this widget neither starts extra probes nor changes that config. Its result describes that check, not a guarantee that every website works. Disabled or unavailable checks are treated as unknown, rather than accepting an untested green state. A connected device with `None`, `Limited`, or `Portal` connectivity gets peach; `Full` gets green. No connected device means gray regardless of a previous connectivity result.

## Deploying and previewing it

The implementation lives under `default/quickshell/`, so both fresh and existing installations read it directly. It requires Quickshell's Networking module and the existing NetworkManager and Kitty packages, with no new seed or migration. Restart `quickshell.service` to apply it to an existing session.

For visual review, `NetworkPreview` can supply mock state to every monitor without changing any network settings. After restarting Quickshell, run:

```bash
qs -p "$HANDAAN_PATH/default/quickshell" ipc call -- networkPreview show offline wifi
qs -p "$HANDAAN_PATH/default/quickshell" ipc call -- networkPreview show portal wired
qs -p "$HANDAAN_PATH/default/quickshell" ipc call -- networkPreview show live wifi
```

Modes are `online`, `offline` (connected without internet), `portal`, `disconnected`, `unknown`, and `live`; transports are `wifi` and `wired`. Each preview expires after ten minutes, and restarting the bar restores live data. The preview is held only in memory and leaves tooltip styling intact.
