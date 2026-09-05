# OS-portable by default

Favour solutions that work on both targets. Isolate platform-specific package and service differences in setup and maintenance scripts.

There are two targets: Arch Linux running the full desktop, and a headless Debian LXC. Configuration that assumes `pacman`, or assumes a compositor is running, silently breaks the second one — usually at shell startup, where it is most annoying to debug.

The isolation lives in the scripts, not in the config. Distribution differences belong in `install/` and in the `handaan-*` commands, which already separate by platform: `bin/handaan-update` and `bin/handaan-lxc-setup` are the pattern to extend rather than to work around. Nothing under `config/` or the root dotfiles currently carries a platform guard, and the way to keep it that way is to put the difference in a script rather than a conditional in `zshrc`.

Portability is a default, not an absolute. Hyprland is Arch-side and always will be. The rule is to avoid *unnecessary* assumptions — a hardcoded package manager in a shell alias is unnecessary; a compositor config is not.
