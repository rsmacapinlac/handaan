echo "Make NetworkManager the only network manager"

# Machines installed from an archinstall profile with "copy ISO network
# configuration" also run systemd-networkd, driven by archiso's
# /etc/systemd/network/20-*.network files. It and NetworkManager both took a
# DHCP lease on the same Wi-Fi interface, installed two default routes, and
# turned every NetworkManager reconnect into a networkd lease loss and route
# rebuild. The profiles now ask archinstall for NetworkManager, and
# install/post-install/network.sh is the fresh path; this is the backfill.
#
# networkd is part of the systemd package, so it is masked rather than removed.
# It is stopped now only if NetworkManager is running to take over; otherwise
# stopping it could leave the machine offline mid-update. iwd is removed unless
# NetworkManager uses it as its Wi-Fi backend. systemd-resolved is left alone.
#
# Idempotent: masking a masked unit, and checking for files and a package that
# are already gone, changes nothing.

stop=""
if systemctl is-active --quiet NetworkManager.service; then
    stop="--now"
else
    echo "  NetworkManager is not running; networkd is masked but left up until reboot"
fi

was_active=0
systemctl is-active --quiet systemd-networkd.service && was_active=1

for unit in systemd-networkd.service systemd-networkd.socket \
    systemd-networkd-wait-online.service; do
    sudo systemctl disable ${stop:+"$stop"} "$unit" 2>/dev/null || true
    if [[ $(systemctl is-enabled "$unit" 2>/dev/null) != masked ]]; then
        sudo systemctl mask "$unit"
        echo "  masked $unit"
    fi
done

for file in /etc/systemd/network/20-{ethernet,wlan,wwan}.network; do
    [[ -e $file ]] || continue
    pacman -Qo "$file" &>/dev/null && continue
    sudo rm -f "$file"
    echo "  removed $file"
done

if pacman -Q iwd &>/dev/null; then
    if grep -rqs '^[[:space:]]*wifi\.backend[[:space:]]*=[[:space:]]*iwd' \
        /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/conf.d; then
        echo "  NetworkManager uses iwd as its Wi-Fi backend; leaving iwd installed"
    else
        sudo systemctl disable --now iwd.service 2>/dev/null || true
        sudo pacman -Rns --noconfirm iwd
        echo "  removed iwd"
    fi
fi

# A stopped networkd leaves its address and route in place by design. They go
# at the next reboot, or now with a reconnect -- not done here, since bouncing
# the link in the middle of an update would drop the update's own connection.
if (( was_active )) && [[ -n $stop ]]; then
    echo "  networkd's lease and route linger until reboot or: nmcli device reconnect <iface>"
fi
