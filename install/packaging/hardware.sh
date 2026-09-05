#!/bin/bash
log_info "Installing hardware and system integration..."
yay_install_list "$HANDAAN_INSTALL/hardware.packages"
sudo usermod -a -G lp "$USER"
