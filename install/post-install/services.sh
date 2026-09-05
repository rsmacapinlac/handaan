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
for unit in hypridle hyprpaper mako hyprpolkitagent; do
    systemctl --user enable "$unit.service" 2>/dev/null \
        || log_warning "Could not enable $unit.service"
done

# The Quickshell bar. Unlike the units above this one is ours, seeded into
# ~/.config/systemd/user by the config phase, and its ExecStart points at the
# QML in $HANDAAN_PATH/default/quickshell. waybar is deliberately left
# un-enabled beside it as a fallback bar.
systemctl --user enable quickshell.service 2>/dev/null \
    || log_warning "Could not enable quickshell.service"
