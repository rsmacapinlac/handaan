#!/bin/bash
log_info "Configuring the UTF-8 locale..."
sudo sed -i 's/^#\?en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
echo 'LANG=en_US.UTF-8' | sudo tee /etc/locale.conf >/dev/null
