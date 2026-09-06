# Privacy: what belongs in the public tree

This repository is public and holds defaults. Configuration that identifies one person, and configuration the owner has chosen to keep out of the public tree, lives in a separate private repo, which is **not named here** — a public repository naming a private one is itself the kind of disclosure this split exists to prevent.

The private repo owns its own deployment. It seeds `~/.config` the same copy-model way handaan seeds it from `config/`: copy once, refuse to clobber, never touch the file again. The two trees currently hold disjoint files, so there is nothing to override — if that ever changes, whichever tree seeds second has to skip anything the other already placed, the way `rcm`'s first-tree-wins ordering used to before handaan moved off it (see [0003](../decisions/adrs/0003-install-into-a-single-owned-tree.md)).

Identity held privately: `mbsyncrc`, `msmtprc`, the personal `neomutt/neomuttrc` and `neomutt/accounts/`, `gitconfig`, `claude/settings.json`, the mail scripts `bin/sync-mail` and `bin/neomutt-accounts` with their zsh completion, and the device-specific `bin/sync-hifiwalker` and `bin/backup-workspace`.

Preferences held privately by choice, not because they identify anyone: the zsh setup — `zshrc`, `zshenv`, the aliases, and the app that installs zsh and runs `chsh` — plus `beets`, `cava`, `chromium-flags.conf`, the rest of `claude`, `cups`, `Cursor`, `fastfetch`, `kitty`, `nvim`, `pi`, `polybar`, `qutebrowser`, `ranger`, `wal`, and tmux — `tmux.conf`, the app that installs tmux and its TPM plugins, and `bin/tat`. None of these would be wrong on someone else's machine — they moved because the owner wanted a smaller public tree, not because the test below reclassified them. neomutt's own `colors`, `mailcap` and `mappings` briefly lived here too and were deleted outright rather than kept anywhere, once it was clear they weren't needed. Hyprland, hyprlock, hypridle, hyprpaper, rofi, waybar and mako are the deliberate exception: they stay in handaan even though they are just as much a preference. Rofi and waybar are there because `default/hypr/binds.lua` execs their scripts by absolute path; mako is core notification/lock-adjacent chrome the owner chose to keep alongside the rest of the desktop stack rather than a technical dependency the way the others are.

What is left in `bin/` is generic: `terminal-notify` and `pinentry-wrapper`, which `install.sh` writes into `gpg-agent.conf`. `tat` was here too and moved out with tmux — it drives a tool core no longer installs, and a wrapper is not much use in a different repository from the thing it wraps. `terminal-notify` also uses tmux, but only when it finds it, and works without it.

## Deciding where a file belongs

Before adding a file, decide which tree it belongs in:

- Would it be wrong or useless on someone else's machine? It is identity, and belongs in the private repo. Real names, addresses, account lists, GPG signing keys, and anything naming a private repository all qualify. Code counts too: a script that hardcodes one person's accounts is identity, not logic, until it is parameterised.
- Is it a fact about one machine rather than one person? Prefer generating it during setup over tracking it, the way `gnupg/gpg-agent.conf` is excluded here and written by `install.sh`.
- Otherwise it is a preference, and normally belongs here — unless the owner deliberately wants it out of the public tree, in which case it goes to the private repo as a preference, not as identity. Say so explicitly rather than stretching the identity test to justify it.

## Rules that hold either way

- Do not add secrets, tokens, private keys, passwords, or local-only network share details.
- Internal hostnames are covered by that rule. Do not commit anything under a private domain, including in browser bookmarks, docs, or example configs.
- Email configs retrieve passwords through `pass`; preserve that pattern.
- Be careful with files under `gnupg/`, mail configs, SSH/GPG setup sections, and setup scripts that copy sensitive material.
- Tracked build artifacts can outlive the source they came from. A `.pyc` kept both hostnames as string constants after `config.py` was cleaned, and `.gitignore` does not untrack what git already tracks.
