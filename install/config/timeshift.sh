#!/bin/bash
# Snapshot before every pacman upgrade. See docs/decisions/adrs/0001.

log_info "Installing Timeshift's pacman snapshot hook..."
yay_install timeshift-autosnap

# timeshift-autosnap is a PreTransaction hook on Upgrade: it asks Timeshift
# for a snapshot before every `pacman -Syu`. Timeshift itself needs a config
# to do anything, and neither the Archinstall profile nor this installer used
# to create one -- so the hook ran on every upgrade and quietly did nothing.
local conf=/etc/timeshift/timeshift.json
if [[ -f $conf ]]; then
    log_info "Timeshift is already configured; leaving $conf untouched"
    return 0
fi

local fstype uuid
fstype=$(findmnt -no FSTYPE / 2>/dev/null || true)
uuid=$(findmnt -no UUID / 2>/dev/null || true)

if [[ $fstype != btrfs ]]; then
    log_warning "Root is $fstype, not btrfs; skipping Timeshift setup."
    log_warning "Configure Timeshift by hand if you want snapshots."
    return 0
fi
if [[ -z $uuid ]]; then
    log_warning "Could not determine the root filesystem UUID; skipping Timeshift setup."
    return 0
fi

# BTRFS mode requires the Ubuntu-style @ / @home layout, which the
# Archinstall profiles create. Scheduled snapshots stay off: the point here
# is a snapshot before package upgrades, which the hook triggers.
log_info "Configuring Timeshift in BTRFS mode on $uuid..."
sudo mkdir -p /etc/timeshift
sudo tee "$conf" >/dev/null <<EOF
{
  "backup_device_uuid" : "$uuid",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "true",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "false",
  "schedule_daily" : "false",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [],
  "exclude-apps" : []
}
EOF
log_success "Timeshift configured; upgrades will snapshot first"
