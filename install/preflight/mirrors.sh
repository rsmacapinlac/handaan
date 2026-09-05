#!/bin/bash
# A stale mirror list makes every later step slow, so this runs before the first
# large transaction rather than after it.

log_info "Updating package mirrors..."
if ! command -v reflector &>/dev/null; then
    sudo pacman -S --needed --noconfirm reflector
fi

if sudo reflector \
    --country 'United States,Canada' \
    --latest 5 \
    --protocol https \
    --sort score \
    --save /etc/pacman.d/mirrorlist 2>/dev/null; then
    log_success "Package mirrors updated"
else
    log_warning "Reflector failed; retaining the existing mirror list"
fi
