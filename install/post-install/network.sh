#!/bin/bash
# NetworkManager is handaan's network stack: services.sh enables it and the
# bar's network widget reads its state. Any other manager left behind fights
# it for the same interfaces. archinstall's "copy ISO network configuration"
# leaves systemd-networkd enabled with /etc/systemd/network/20-*.network
# matching every wlan and ethernet link, so both took a DHCP lease on one
# interface, installed two default routes, and every NetworkManager reconnect
# became a networkd lease loss and route rebuild. See
# docs/decisions/adrs/0011-one-network-manager-owns-the-interfaces.md.
#
# Managers are masked, not uninstalled: networkd ships inside the systemd
# package, and iwd may be installed on purpose or depended on. A masked unit
# cannot start by socket, dependency or hand. Nothing is stopped here: during
# install it may be the only thing keeping the machine online, and
# NetworkManager takes over at the reboot. systemd-resolved stays; it is a
# resolver, not a manager, and NetworkManager hands it DNS.

log_info "Making NetworkManager the only network manager..."

for unit in systemd-networkd.service systemd-networkd.socket \
    systemd-networkd-wait-online.service; do
    sudo systemctl disable "$unit" 2>/dev/null || true
    sudo systemctl mask "$unit"
done

# Only archiso's own files, recognised by the issue link in their comments; a
# hand-written .network file is inert with networkd masked, so it is left alone.
for file in /etc/systemd/network/20-{ethernet,wlan,wwan}.network; do
    [[ -e $file ]] || continue
    grep -q 'systemd/issues/17698' "$file" || continue
    sudo rm -f "$file"
    log_info "Removed archiso's $file"
done

# iwd is a second Wi-Fi daemon beside NetworkManager's wpa_supplicant, unless
# NetworkManager's merged config points at it as its backend.
if [[ -n $(systemctl list-unit-files --no-legend iwd.service 2>/dev/null) ]]; then
    nm_config=$(NetworkManager --print-config 2>/dev/null || true)
    if grep -Eq '^[[:space:]]*wifi\.backend[[:space:]]*=[[:space:]]*iwd' <<<"$nm_config"; then
        log_info "NetworkManager uses iwd as its Wi-Fi backend; leaving iwd alone"
    else
        sudo systemctl disable iwd.service 2>/dev/null || true
        sudo systemctl mask iwd.service
    fi
fi
