# 0006. Leave the login shell to the user

Status: accepted

## Context

handaan installed `zsh`, ran `sudo chsh -s /bin/zsh "$USER"`, installed Oh My Zsh, and seeded `~/.zshrc` and `~/.zshenv` as stubs sourcing a body it kept under `default/zsh/`. That body was not a default in any minimal sense — it carried a prompt, an Oh My Zsh theme and plugin list, `EDITOR`, `cdpath`, Go environment variables, `mise activate`, a `g()` git wrapper, and `fastfetch` on every new terminal.

None of that is desktop chrome. [Core stays minimal](../../standards/core-stays-minimal.md) admits something to core when the desktop is unusable without it; a machine with bash as its login shell is a perfectly usable desktop. The shell was in core for the historical reason that handaan grew out of a dotfile repository where it had always lived, not because anything in the compositor, bar or session needed it.

Keeping it there had a cost beyond taste. `chsh` changed the account's login shell without asking, on every fresh install. The Oh My Zsh installer writes its own `~/.zshrc` from a template, which once silently beat the seed's `[[ ! -f ]]` guard and needed both an ordering fix and a migration to repair. And because the body was read live out of `$HANDAAN_PATH`, a `git pull` could change the prompt and aliases of a machine whose owner had never asked handaan to have an opinion about either.

The mechanism for shipping a preference like this already existed: [0005](0005-accept-user-owned-optional-applications.md) put optional applications in the user's own dotfile repository, discovered from `~/.config/handaan/apps/<name>/`.

## Decision

handaan installs no shell, sets no login shell, and seeds no shell startup file.

| Was | Is |
| --- | --- |
| `zsh` in `install/base.packages` | not installed by core |
| `sudo chsh -s /bin/zsh` in `install/config/shell.sh` | not run; the account keeps whatever shell it has |
| Oh My Zsh installed by core | not installed by core |
| `~/.zshrc`, `~/.zshenv` seeded by core | not seeded; the user's dotfile repository supplies them |
| `default/zsh/{rc,aliases,env}` | removed |
| `install/config/shell.sh` | `install/config/home-dotfiles.sh`, holding only the `.vimrc`/`.face` seeds it also had |

A user who wants zsh ships it as an app under `~/.config/handaan/apps/zsh/` — `packages` for `zsh`, `install.sh` for the `chsh` and the Oh My Zsh install — and deploys the rc files by whatever mechanism that repository already uses.

**`default/shell/env-bootstrap` stays, and stays handaan's.** It is POSIX `sh`, not zsh, and it is the single source of truth for `$HANDAAN_PATH` and the `PATH` entries that depend on it ([0003](0003-install-into-a-single-owned-tree.md)). `install/config/env-bootstrap.sh` still writes it into `/etc/profile.d/handaan.sh` and `~/.config/uwsm/env`, which between them cover every login shell and the graphical session. What core no longer covers is a *non-login interactive* shell, which reads neither — so a user-supplied `~/.zshenv` has to source `env-bootstrap` itself, and the handover migration writes one that does. Getting this wrong is the failure 0003 already records: `handaan-*` comes up "command not found" in a new terminal on a machine that is otherwise installed correctly.

## Consequences

A fresh install now leaves the account on bash. That is a visible change in the out-of-the-box experience and it is intended: choosing someone's login shell is not a decision an install of a compositor gets to make. `install/post-install/finished.sh` already points at `handaan apps`, which is where the choice now lives.

Existing machines carry a stub pointing at files this change deletes, so the shell would come up bare and noisy after a `git pull`. `migrations/1788722539.sh` hands the configuration over rather than dropping it: it recovers `default/zsh/{rc,aliases,env}` from git history — the pull has already deleted them from the worktree by the time migrations run — copies them to `~/.zsh/`, and repoints the stubs there. It refuses to touch a `~/.zshrc` that another dotfile manager has symlinked into its own checkout, because writing through that symlink would edit the source repository instead of the machine.

The shell configuration stops receiving handaan improvements through `git pull`. Since it is now a copy in `~/.zsh/` or a file in someone else's repository, that is the point rather than a regression — but it does mean a fix to a shared alias no longer reaches anyone automatically.
