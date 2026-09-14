#!/bin/bash
log_info "Enabling core services..."
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable bolt.service 2>/dev/null || true
sudo systemctl enable cups.service
sudo systemctl enable avahi-daemon.service

systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable ssh-agent.service 2>/dev/null || true
systemctl --user enable gnome-keyring-daemon 2>/dev/null || true

# The session runs under uwsm, which activates graphical-session.target, so
# these packaged units start and stay supervised. Without a session manager the
# target never activates and enabling them would be a no-op -- that is exactly
# how hypridle silently never ran. default/hypr/autostart.lua must not also
# exec these, or each gets a second, unsupervised copy.
for unit in hypridle hyprpaper hyprpolkitagent; do
    systemctl --user enable "$unit.service" 2>/dev/null \
        || log_warning "Could not enable $unit.service"
done

# Notifications are the Quickshell shell's (Commons/NotificationCenter.qml), and
# only one program can own org.freedesktop.Notifications. mako stays installed
# as the fallback while that proves itself, but masked, not merely disabled: its
# package ships a D-Bus activation file that would start it the first time
# anything notified before the shell was up, and the shell would never get the
# name. See docs/decisions/adrs/0008-notifications-are-part-of-the-desktop-shell.md.
systemctl --user disable mako.service >/dev/null 2>&1 || true
systemctl --user mask mako.service >/dev/null 2>&1 \
    || log_warning "Could not mask mako.service"

# The Quickshell bar. Unlike the units above this one is ours, seeded into
# ~/.config/systemd/user by the config phase, and its ExecStart points at the
# QML in $HANDAAN_PATH/default/quickshell.
systemctl --user enable quickshell.service 2>/dev/null \
    || log_warning "Could not enable quickshell.service"
