set -euo pipefail

echo "Make NetworkManager the only network manager"

# Machines installed from an archinstall profile with "copy ISO network
# configuration" also run systemd-networkd, driven by archiso's
# /etc/systemd/network/20-*.network files. It and NetworkManager both took a
# DHCP lease on the same Wi-Fi interface, installed two default routes, and
# turned every NetworkManager reconnect into a networkd lease loss and route
# rebuild. The profiles now ask archinstall for NetworkManager, and
# install/post-install/network.sh is the fresh path; this is the backfill.
#
# networkd and iwd are masked rather than uninstalled: networkd is part of the
# systemd package, and iwd may be installed on purpose or depended on. They are
# stopped now only if NetworkManager is running to take over; otherwise
# stopping them could leave the machine offline mid-update. systemd-resolved
# is left alone.
#
# Strict mode, because handaan-migrate marks a migration done on exit 0: a
# failed mask or removal must fail the migration, not be stamped as applied.
# Idempotent: masked units and absent files are skipped.

stop=""
if systemctl is-active --quiet NetworkManager.service; then
    stop="--now"
else
    echo "  NetworkManager is not running; units are masked but left up until reboot"
fi

was_active=0
systemctl is-active --quiet systemd-networkd.service && was_active=1

mask() {
    local unit=$1
    [[ $(systemctl is-enabled "$unit" 2>/dev/null || true) == masked ]] && return 0
    sudo systemctl disable ${stop:+"$stop"} "$unit" 2>/dev/null || true
    sudo systemctl mask "$unit"
    echo "  masked $unit"
}

for unit in systemd-networkd.service systemd-networkd.socket \
    systemd-networkd-wait-online.service; do
    mask "$unit"
done

# Only archiso's own files, recognised by the issue link in their comments; a
# hand-written .network file is inert with networkd masked, so it is left alone.
for file in /etc/systemd/network/20-{ethernet,wlan,wwan}.network; do
    [[ -e $file ]] || continue
    if ! grep -q 'systemd/issues/17698' "$file"; then
        echo "  $file is not archiso's; left in place, inert while networkd is masked"
        continue
    fi
    sudo rm -f "$file"
    echo "  removed archiso's $file"
done

if [[ -n $(systemctl list-unit-files --no-legend iwd.service 2>/dev/null) ]]; then
    nm_config=$(NetworkManager --print-config 2>/dev/null || true)
    if grep -Eq '^[[:space:]]*wifi\.backend[[:space:]]*=[[:space:]]*iwd' <<<"$nm_config"; then
        echo "  NetworkManager uses iwd as its Wi-Fi backend; leaving iwd alone"
    else
        mask iwd.service
    fi
fi

# A stopped networkd leaves its address and route in place by design. They go
# at the next reboot, or now with a reconnect -- not done here, since bouncing
# the link in the middle of an update would drop the update's own connection.
if (( was_active )) && [[ -n $stop ]]; then
    echo "  networkd's lease and route linger until reboot or: nmcli device reconnect <iface>"
fi
exit 0
