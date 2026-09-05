# Privacy: what belongs in the public tree

This repository is public and holds defaults. Configuration that identifies one person lives in a separate private repo, which is **not named here** — a public repository naming a private one is itself the kind of disclosure this split exists to prevent.

That repo ships its own `rcrc` listing both trees, itself first: `rcm` deploys the first tree providing a path, so private files override public defaults. Reversing that order silently shadows the real config with the default, which is a failure mode worth remembering.

Identity currently held privately: `mbsyncrc`, `msmtprc`, the personal `config/neomutt/neomuttrc` and `config/neomutt/accounts/`, `gitconfig`, `claude/settings.json`, the mail scripts `bin/sync-mail` and `bin/neomutt-accounts` with their zsh completion, and the device-specific `bin/sync-hifiwalker` and `bin/backup-workspace`.

What is left in `bin/` is generic: `tat`, `terminal-notify`, and `pinentry-wrapper`, which `install.sh` writes into `gpg-agent.conf`.

Where a public default is useful, keep one and let the private tree override it, the way `config/neomutt/neomuttrc` ships an account-free default here.

## Deciding where a file belongs

Before adding a file, decide which tree it belongs in:

- Would it be wrong or useless on someone else's machine? It is identity, and belongs in the private repo. Real names, addresses, account lists, GPG signing keys, and anything naming a private repository all qualify. Code counts too: a script that hardcodes one person's accounts is identity, not logic, until it is parameterised.
- Is it a fact about one machine rather than one person? Prefer generating it during setup over tracking it, the way `gnupg/gpg-agent.conf` is excluded here and written by `install.sh`.
- Otherwise it is a preference, and belongs here.

## Rules that hold either way

- Do not add secrets, tokens, private keys, passwords, or local-only network share details.
- Internal hostnames are covered by that rule. Do not commit anything under a private domain, including in browser bookmarks, docs, or example configs.
- Email configs retrieve passwords through `pass`; preserve that pattern.
- Be careful with files under `gnupg/`, mail configs, SSH/GPG setup sections, and setup scripts that copy sensitive material.
- Tracked build artifacts can outlive the source they came from. A `.pyc` kept both hostnames as string constants after `config.py` was cleaned, and `.gitignore` does not untrack what git already tracks.
