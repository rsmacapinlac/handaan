#!/bin/bash
# gpg-agent.conf is written here rather than shipped, because the pinentry path
# is absolute and machine-specific -- tracking it would put one machine's layout
# into everyone's checkout.

gpg_conf="$HOME/.gnupg/gpg-agent.conf"
mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"

# A machine migrating off rcm may still have this as a symlink into the old
# checkout. Writing through it would edit the repository, so break it first.
if [[ -L $gpg_conf ]]; then
    cp "$gpg_conf" "$gpg_conf.tmp"
    mv "$gpg_conf.tmp" "$gpg_conf"
fi
touch "$gpg_conf"

grep -q '^default-cache-ttl ' "$gpg_conf" || \
    printf '# Default cache TTL (2 hours)\ndefault-cache-ttl 7200\n' >> "$gpg_conf"
grep -q '^max-cache-ttl ' "$gpg_conf" || \
    printf '\n# Maximum cache TTL (12 hours)\nmax-cache-ttl 43200\n' >> "$gpg_conf"
grep -q '^pinentry-program ' "$gpg_conf" || \
    echo "pinentry-program $HANDAAN_PATH/bin/pinentry-wrapper" >> "$gpg_conf"

gpgconf --kill gpg-agent 2>/dev/null || true

log_warning "SSH/GPG keys and the password store are not restored automatically."
log_warning "Follow the manual restore instructions in README.md after rebooting."
