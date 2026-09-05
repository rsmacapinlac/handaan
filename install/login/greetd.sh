#!/bin/bash
# greetd launches the session through uwsm, which activates
# graphical-session.target -- the target every packaged user unit attaches to.
# Without it those units are enabled but never started. See
# docs/hyprland-startup.md.

log_info "Installing and configuring greetd..."
sudo systemctl disable sddm 2>/dev/null || true
sudo systemctl stop sddm 2>/dev/null || true
yay -Rns --noconfirm sddm 2>/dev/null || true
yay_install greetd

sudo mkdir -p /etc/greetd
sudo tee /etc/greetd/config.toml >/dev/null <<GREETD
[terminal]
vt = 1

[default_session]
command = "uwsm start -- start-hyprland"
user = "greeter"

[initial_session]
command = "uwsm start -- start-hyprland"
user = "$USER"
GREETD
sudo systemctl enable greetd
