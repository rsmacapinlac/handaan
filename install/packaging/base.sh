#!/bin/bash
log_info "Installing core system and terminal packages..."
# Superseded by polkit-kde-agent and hyprpolkitagent; removing them first keeps
# two authentication agents from racing for the same D-Bus name.
yay -Rns --noconfirm ksshaskpass polkit-gnome 2>/dev/null || true
yay_install_list "$HANDAAN_INSTALL/base.packages"
