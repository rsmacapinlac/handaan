# 0011. One network manager owns the interfaces

Status: accepted

## Context

handaan installs and enables NetworkManager, and the bar's network widget reads its state. The base system underneath comes from archinstall, whose "copy ISO network configuration" option (`"network_config": {"type": "iso"}`, which both saved profiles used) carries archiso's networking onto the installed system: systemd-networkd enabled, with `/etc/systemd/network/20-{ethernet,wlan,wwan}.network` matching every wired, wireless and mobile link.

Nothing stopped the two from running together. On urakara both managed `wlp61s0`: two DHCP leases, two default routes at metric 600, networkd logging that "foreign process NetworkManager" had changed its sysctls, and every NetworkManager reconnect (roaming, MAC randomisation while scanning) showing up in networkd as a lost carrier and a fresh DHCP exchange. On a network that roams often, every short drop turned into rebuilding the routes.

## Decision

NetworkManager is the only network manager.

| what | how |
|---|---|
| archinstall profiles | `"network_config": {"type": "nm"}`, so the base system boots into NetworkManager rather than archiso's stack |
| systemd-networkd (`.service`, `.socket`, `-wait-online.service`) | disabled and masked by `install/post-install/network.sh`; it ships inside `systemd`, so it cannot be uninstalled, and a merely disabled unit can still be socket-activated |
| `/etc/systemd/network/20-*.network` | deleted only when their contents are archiso's, recognised by the systemd issue link in their comments; any other file there is left alone, inert while networkd is masked |
| iwd | disabled and masked, not uninstalled, unless NetworkManager's merged config (`NetworkManager --print-config`) sets `wifi.backend=iwd`; the package may be wanted or depended on |
| wpa_supplicant | kept; it is NetworkManager's Wi-Fi backend, started on demand over D-Bus |
| systemd-resolved | kept; it is a resolver, not a manager, and NetworkManager hands it DNS when `/etc/resolv.conf` points at its stub |

The installer masks networkd without stopping it, because during the install it may be the only thing keeping the machine online. NetworkManager takes over at the reboot. Migration `1794756558` applies the same cleanup to machines that are already installed, and stops networkd straight away only when NetworkManager is already running. It runs under `set -euo pipefail`, because `handaan-migrate` marks a migration done on exit 0, and a failed mask must not be recorded as applied.

The profile change is not enough on its own. A user can pick archinstall's interactive option, or bring a profile of their own, so the install step enforces the outcome whatever the base system arrived with.
