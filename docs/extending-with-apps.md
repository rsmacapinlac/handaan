# Extending handaan with your own applications

handaan installs a minimal desktop and stops there. Everything past that — your browser, your editor, your shell, your development tooling — is yours, and you add it without forking handaan or asking anyone to add it on your behalf.

You define an **app** as a folder. You configure one, handaan discovers it, and `handaan apps` offers it alongside the others.

## The two trees

Two repositories are in play, owned by different people, and knowing which is which is most of the job:

- **handaan** — the desktop itself, checked out at `$HANDAAN_PATH` (`~/.local/share/handaan` by default). It is read-only to you: a `git pull` replaces it, so an app added there is lost on the next update. Refer to files inside it as `$HANDAAN_PATH/...` and never hardcode the path — the tree is relocatable.
- **your dotfiles repository** — where the apps you write actually live. It deploys them to `~/.config/handaan/apps/`, which handaan reads and never writes to.

Everything below is the contract between the two. Nothing in it requires editing handaan.

## Where an app lives

```
~/.config/handaan/apps/<name>/
```

Every directory found is an app. The name of the directory is the name of the app — it is what the installer lists, what you search for, and what you pass on the command line, so keep it short, lowercase, and free of spaces and tabs.

That location is deliberately outside handaan's own tree. It belongs to your dotfiles repository, and you get it into place by symlinking or copying it there.

There is no registry to add yourself to. The directory existing is the registration.

## Anatomy

| file | required | what it does |
|---|---|---|
| `meta` | **required** | Names the app in the installer, with a one-line summary. |
| `packages` | optional | Package list installed with `yay`. |
| `install.sh` | optional | Sourced once, each time the app is selected. One-time setup. |
| `update.sh` | optional | Sourced on every `handaan update`. Ongoing maintenance. |
| `config/` | optional | Mirrors `$HOME`. Copied in without clobbering, when the app is selected. |

Only `meta` is required. The other four are independent of each other — an app can be a package list and nothing else, or a `config/` tree and nothing else. Anything else you keep in the directory (a `README.md`, a helper script, a wallpaper) is ignored by handaan and available to your own scripts.

When an app is installed, the three steps run in this order: **packages, then `install.sh`, then `config/`.** So `install.sh` cannot assume its own `config/` files have landed yet.

### `meta`

One line, in the same `# handaan:summary=` form the `handaan-*` commands use for themselves:

```
# handaan:summary=Terminal multiplexer, with my keybindings.
```

The first matching line wins. An app with no `meta` is still discovered and still installs, but it lists in the installer as a bare name with nothing beside it — and the summary is searched as well as shown, so an app without one is harder to find. Write one.

### `packages`

One package per line, official repositories or AUR — `yay` resolves both. Comments and blank lines are stripped, so the list can explain itself:

```
# The multiplexer itself.
tmux

# Clipboard bridge; tmux copy-mode is useless without it on Wayland.
wl-clipboard
```

Keep comments on their own line rather than trailing a package name — that is how handaan's own package lists (`$HANDAAN_PATH/install/*.packages`) are written, and the stripping is happiest with it.

Installation is `yay -S --needed`, so a package already present is left alone and re-running costs nothing.

Declaring packages here is not what makes handaan consider the app installed, but they are checked; see [How handaan decides an app is installed](#how-handaan-decides-an-app-is-installed).

### `install.sh`

For the one-time setup a package install does not cover: enabling a systemd unit, loading a module, adding your user to a group, creating a state directory, fetching a plugin manager.

It is **sourced**, not executed — no shebang needed, and no `set -euo pipefail` of its own. It runs in a subshell, so variables you set do not leak into other apps.

Inside it you have:

- the log helpers — `log_info`, `log_success`, `log_warning`, `log_error`. Use them rather than `echo`, so your app's output reads like the rest of the run.
- `yay_install <pkg>...` and `yay_install_list <file>`, if you need to install something conditionally.
- `$HANDAAN_PATH` and `$HANDAAN_STATE`, already set and exported.
- `sudo` without a password prompt, for the duration of the run.
- `set -euo pipefail`, inherited from `handaan-apps-install`. **Any command that fails ends the whole install run**, including the apps queued behind yours. Append `|| true` where a non-zero exit is acceptable.

The working directory is wherever the install was started from, which is `$HOME` when it came from the installer dialog. Use absolute paths, and reach your own files through the script's own location:

```bash
app_dir=$(dirname "${BASH_SOURCE[0]}")
```

It runs again every time the app is chosen, including when it is already installed. Write it so that is harmless.

### `update.sh`

Sourced on **every** `handaan update`, for maintenance a package upgrade does not catch — refreshing plugins, re-linking something, pruning a cache.

The same environment applies, with two differences worth knowing:

- It runs for **every app directory present**, whether or not you ever installed that app. Guard on the thing you are maintaining rather than assuming it is there:

  ```bash
  command -v tmux &>/dev/null || return 0
  ```

- `sudo` here **will prompt**. `handaan update` does not enable the passwordless rule that `handaan-apps-install` does. An unattended-looking update that stops on a password prompt is usually a `sudo` in an `update.sh`.

Strict mode applies here too: a failure aborts the update before it reaches mise, Neovim and the config-drift report. Be conservative.

The distinction against a migration is scope. A migration repairs one thing once, on machines that predate a fix. An `update.sh` is ongoing work that runs forever.

### `config/`

A tree that mirrors `$HOME`, copied in wholesale when the app is selected:

```
config/.config/tmux/tmux.conf
config/.local/share/applications/tmux.desktop
```

lands as `~/.config/tmux/tmux.conf` and `~/.local/share/applications/tmux.desktop`.

The copy is **no-clobber**. A file that already exists in `$HOME` is left exactly as it is — the same rule handaan applies to its own `config/` seed, for the same reason: your live configuration is yours, and nothing here is allowed to overwrite it.

The consequence catches everyone once. **Editing a file in your app's `config/` does not change a machine where the app is already installed.** The copy in `$HOME` already exists and wins. To take the new version, delete or move your local copy and re-run `handaan apps-install <name>`, or just apply the edit to `$HOME` yourself.

Note also that `.desktop` overrides for your applications belong here, not in handaan — handaan seeds only overrides for packages it installs itself.

## A worked example

handaan installs no shell and no multiplexer on purpose; both come with configuration that is yours. So tmux is the natural first app.

```bash
mkdir -p ~/.config/handaan/apps/tmux/config/.config/tmux

cat > ~/.config/handaan/apps/tmux/meta <<'EOF'
# handaan:summary=Terminal multiplexer, with my keybindings.
EOF

cat > ~/.config/handaan/apps/tmux/packages <<'EOF'
tmux
wl-clipboard
EOF

cat > ~/.config/handaan/apps/tmux/install.sh <<'EOF'
# The plugin manager tmux.conf expects. Cloned once; a second run is a no-op.
tpm="$HOME/.tmux/plugins/tpm"
if [[ ! -d $tpm ]]; then
    log_info "Installing tpm..."
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm"
fi
EOF

cat > ~/.config/handaan/apps/tmux/update.sh <<'EOF'
# Only meaningful once tmux is actually on the machine.
command -v tmux &>/dev/null || return 0
[[ -x "$HOME/.tmux/plugins/tpm/bin/update_plugins" ]] || return 0

log_info "Updating tmux plugins..."
"$HOME/.tmux/plugins/tpm/bin/update_plugins" all || log_warning "tmux plugin update failed"
EOF

cp ~/my-dotfiles/tmux.conf ~/.config/handaan/apps/tmux/config/.config/tmux/tmux.conf
```

Then:

```bash
handaan apps-install tmux
```

## Installing

```bash
handaan apps                        # open the installer (also SUPER+SHIFT+A)
handaan apps-install tmux neovim    # install these, no dialog
handaan apps-install all            # install everything found
handaan apps-manifest               # the catalogue, as JSON
handaan apps-mark tmux              # record as installed without installing
handaan apps-mark --undo tmux       # the reverse
```

The installer is part of the shell rather than a window of its own, so it needs `quickshell.service` running; `handaan apps` says so plainly if it is not. Everything else works from a TTY with no session at all.

The installer is a launcher, not a form. Type to narrow the list, `↑`/`↓` to move, `Enter` to install the app under the cursor, `Esc` to close. The search matches the app's name *and* its `meta` summary. There is no multi-select: one row, one app.

`Install all pending` sits at the top of the list whenever something is not installed, and is the only thing here that asks twice — the first `Enter` arms it, the second runs it. It installs what is missing, not everything, so it is a no-op on a machine that is already complete.

Already-installed apps stay in the list and stay choosable; the row says `reinstall` rather than `install`. That is deliberate — re-running an app is how you re-apply a `config/` file you have since deleted. There is no uninstall path, by design: removing an app is `yay -Rns` and deleting the files, deliberately, by you.

Before it installs anything, an install run performs a full system upgrade and makes sure `yay` is present, then cleans up orphaned build dependencies afterwards. Budget for that: an install on a machine that has not been updated in a while is not a quick command.

An install started from the dialog opens a terminal of its own and logs the session to `/tmp/handaan-apps.log`; when it fails the window stays open and names that file. Started from a terminal, it just runs there and logs nothing.

The catalogue needs no session, no sudo and no network, which is why it is also what the bar's maintenance indicator counts, via `handaan pending`:

```bash
handaan apps-manifest | jq -r '.[] | select(.installed | not) | .name'
```

An app you write and never install shows up there as work waiting.

## How handaan decides an app is installed

An app counts as installed when **handaan installed it, and every package it still declares is present**. The first half is a marker file that `handaan apps-install` writes at `$HANDAAN_STATE/apps/<name>` (`~/.local/state/handaan/apps/<name>`) once an app's packages, `install.sh` and `config/` have all gone through.

That is the answer to a question the package list alone cannot answer, and getting this wrong is quiet in both directions:

- An app that installs its packages from **inside `install.sh`** — because it needs a repository enabled or a PKGBUILD patched first — declares none. Judged on packages, it can never report installed, so it stays listed as pending and pads `handaan pending` forever.
- An app whose payload is a **`config/` tree** typically names a package it does not own — a browser, say. Judged on packages, it reports installed the moment something *else* pulls that package in. It is then never offered, never selected, and its files are never copied, so the one thing it exists to deliver silently never arrives.

The package check stays on top of the marker, so removing a package by hand puts the app back in the pending list rather than leaving the marker to insist otherwise. It is `pacman -T` that answers it, so a package satisfied by something that *provides* it counts as present, the way pacman itself would judge a dependency.

If an app was installed before handaan started recording this — or you installed it by hand — record it without reinstalling:

```bash
handaan apps-mark <name>...          # record as installed; runs nothing
handaan apps-mark --undo <name>...   # the reverse
```

Marking matters most for the `install.sh` case, where the alternative is a reinstall whose only real effect is the marker. For an app that builds from the AUR, that is a full rebuild to learn nothing.

## Keeping apps in your own repository

The apps root is a directory handaan reads; how it gets there is up to you. Two shapes work:

```bash
# whole root from your repo
ln -s ~/my-dotfiles/handaan-apps ~/.config/handaan/apps

# or one app at a time, mixing repository apps with local scratch ones
mkdir -p ~/.config/handaan/apps
ln -s ~/my-dotfiles/apps/tmux ~/.config/handaan/apps/tmux
```

Discovery follows symlinks to directories, so both are found normally.

Two things to keep in mind about what you put there. First, `install.sh` and `update.sh` are arbitrary shell running with your privileges, including `sudo` — an accepted trust boundary for a repository you own, and a reason not to point the apps root at one you do not. Second, if that repository is public, hold it to the same rules handaan holds its own public tree to:

- No secrets, tokens, private keys, passwords, or local-only network share details.
- No internal hostnames or private domains — including inside a `config/` tree, and including browser bookmarks and example configs.
- Watch tracked build artifacts. A committed `.pyc` can keep a hostname as a string constant long after the source it came from was cleaned, and `.gitignore` does not untrack what git already tracks.

handaan's full policy is at `$HANDAAN_PATH/docs/standards/privacy-policy.md`.

## Things that will bite you

- **A failing command anywhere in `install.sh` or `update.sh` ends the entire run.** Strict mode is inherited. Guard anything allowed to fail.
- **`update.sh` runs even for apps you never installed.** Return early on the app's absence.
- **`sudo` prompts during `handaan update` but not during an app install.**
- **`config/` never overwrites, so editing it later reaches nobody who already has the app.** Same trap as handaan's own `config/` seed, for the same reason.
- **A `config/` copy failure is silent.** The copy suppresses its own errors so one unwritable path cannot abort the run. If a file did not appear, check permissions on the destination.
- **`install.sh` runs before `config/` is copied.** Do not read your own config files from it.
- **Adding an app to handaan's own tree does not work.** It is not a place apps go, and `git pull` replaces it. Apps live in your dotfiles repository, deployed to `~/.config/handaan/apps/`.
- **An app is only "installed" once handaan has installed it.** Writing the app directory is not enough, and neither is having its packages already. Until it goes through `handaan apps-install`, its `config/` has not been copied — the usual symptom is a `.desktop` file that never appears in your launcher.
- **Nothing uninstalls.** Deleting the app directory removes it from the installer, and leaves its packages and files exactly where they are.

## Testing an app before you trust it

Check the syntax of the hooks the way the rest of the tree is checked:

```bash
bash -n ~/.config/handaan/apps/<name>/install.sh ~/.config/handaan/apps/<name>/update.sh
```

Then exercise the real thing:

```bash
handaan apps-install <name>   # packages, install.sh, config/
handaan apps-manifest | jq '.[] | select(.name == "<name>")'   # installed: true
handaan update                # update.sh, on its own
handaan apps-install <name>   # again: proves it is safe to re-run
```

A disposable VM is the honest place for a first run of an app that touches system state; handaan's rehearsal procedure is in `$HANDAAN_PATH/docs/testing-build-scripts.md`. `$HANDAAN_PATH/test/seed-handaan-test-app.sh` writes a complete throwaway app exercising all five files, and is the shortest working reference to read.
