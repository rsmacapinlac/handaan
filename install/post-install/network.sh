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
# networkd ships inside the systemd package, so it cannot be uninstalled; it is
# masked, because it is socket-activated and a merely disabled unit can still be
# started. Nothing is stopped here: during install it may be the only thing
# keeping the machine online, and NetworkManager takes over at the reboot.
# systemd-resolved stays; NetworkManager hands it DNS, and it is not a manager.

log_info "Making NetworkManager the only network manager..."

for unit in systemd-networkd.service systemd-networkd.socket \
    systemd-networkd-wait-online.service; do
    sudo systemctl disable "$unit" 2>/dev/null || true
    sudo systemctl mask "$unit" || log_warning "Could not mask $unit"
done

# archiso's files, copied by archinstall and owned by no package.
for file in /etc/systemd/network/20-{ethernet,wlan,wwan}.network; do
    [[ -e $file ]] || continue
    pacman -Qo "$file" &>/dev/null && continue
    sudo rm -f "$file"
    log_info "Removed $file"
done

# iwd is a second Wi-Fi daemon beside NetworkManager's wpa_supplicant, unless
# NetworkManager was deliberately pointed at it as its backend.
if pacman -Q iwd &>/dev/null; then
    if grep -rqs '^[[:space:]]*wifi\.backend[[:space:]]*=[[:space:]]*iwd' \
        /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/conf.d; then
        log_info "NetworkManager uses iwd as its Wi-Fi backend; leaving iwd installed"
    else
        sudo systemctl disable iwd.service 2>/dev/null || true
        sudo pacman -Rns --noconfirm iwd || log_warning "Could not remove iwd"
    fi
fi
