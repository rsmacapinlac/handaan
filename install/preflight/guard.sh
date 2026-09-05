#!/bin/bash
# Refuse to run where this cannot work. These are fatal on purpose: handaan is
# one person's machine, not a distribution, so "proceed anyway" would only
# produce a broken desktop that is harder to diagnose than a stopped installer.

check_not_root
detect_arch

if [[ $(uname -m) != x86_64 ]]; then
    log_error "handaan targets x86_64; this machine is $(uname -m)."
    exit 1
fi

log_success "Guards passed"
