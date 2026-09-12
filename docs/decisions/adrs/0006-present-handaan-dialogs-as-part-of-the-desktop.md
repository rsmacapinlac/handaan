# 0006. Present handaan's own dialogs as part of the desktop, not as separate applications

Status: accepted

## Context

handaan needs to ask its owner things. An example was picking optional applications to install.

## Decision

**Interactive UI belongs to the shell. Scripts are helpers it calls, never drivers that wait on it.**

Concretely, for the application installer:

| piece | what it is |
|---|---|
| `default/quickshell/Commons/AppCatalog.qml` | Singleton. Reads the catalogue, holds whether the installer is up, spawns an install. Carries the `appCatalog` IPC target. |
| `default/quickshell/Ui/Installer.qml` | The dialog. A layer-shell surface on the focused monitor, bound to `Theme` and `Style` like every widget. |
| `bin/handaan-apps-manifest` | Discovery and installed-state, as JSON. The only place that answers "which apps exist, and which are installed". |
| `bin/handaan-apps-install` | Installs named apps. No terminal, no picker, no log. |
| `bin/handaan-apps-terminal` | Opens a terminal for the above, keeps the session log, holds the window open on failure. |
| `bin/handaan-apps-mark` | Records an install without performing one. |
| `bin/handaan-apps` | Summons the dialog. Nothing else. |

The flow runs one way. `handaan apps` — or `SUPER+SHIFT+A` — calls `appCatalog open`; the shell runs `handaan-apps-manifest` and renders the result; choosing a row hands that app's name to `handaan-apps-terminal` through `execDetached` and closes. Nothing waits for anything: the install pokes `maintenance refresh` when it finishes, and the dialog re-reads the catalogue every time it opens.

The dialog is a launcher rather than a form — type to narrow, arrows to move, `Enter` to install the row under the cursor. Multi-select was dropped because installing one app is the overwhelmingly common case and a checkbox list made it the slowest one, and because a tick that started checked on an already-installed app, and did nothing when cleared, was state with no meaning. `Install all pending` is a row in the same list and the only action that confirms, since it is the one whose cost — a full system upgrade plus every missing app — is not visible from the row.

Data crosses the boundary as **JSON produced by `jq`, with the fields passed as argv rather than interpolated into a filter**, so a summary is free text that cannot terminate a string or displace the field after it.

Two rules fall out of putting a dialog in the shell, and both are load-bearing:

- **The singleton is what receives the IPC call, not the surface.** A surface loaded on demand cannot be asked to appear, because it does not exist yet. `AppCatalog` is always resident and owns the open state; `Installer` binds to it.
- **The singleton and the surface must not share a name.** A type sharing a name with a singleton imported into it shadows that singleton silently — the trap `AGENTS.md` records for `Palette`, and the reason `Maintenance` is not called `Updates`.

## Consequences

The dialog now shares the main process. A QML fault in it is a fault in the shell, where before it could only kill its own short-lived process. `Restart=on-failure` and `StartLimitBurst=5` on `quickshell.service` still apply, and the surface is reached through a type that fails to load rather than taking the process down with it — but the blast radius is genuinely larger, and that is the price of the palette being shared rather than copied.

**A new type in the shell is invisible until the shell restarts, and that deliberately gets no migration.** QML builds its type registry once at launch, so a running shell cannot see a new singleton or IPC target however current the tree is: `handaan apps` answers "Target not found." until the process restarts.

That looks like the case [0004](0004-apply-changes-to-installed-machines.md) exists for, and it is not. A migration backfills *persistent* state that stays broken until something repairs it. This is session state that clears itself, because `quickshell.service` is `PartOf=graphical-session.target` and the next login builds a registry from the current tree. It is also loud rather than silent — `handaan-apps` reads the IPC failure apart from a connection failure and prints the restart command — and silent breakage is what earns a migration its place.

It also would not generalise. The registry is rebuilt at launch *every* time, so every future singleton or IPC target would need a byte-identical migration, in a directory whose value is that each entry marks one real repair.

The cost is a window between `handaan update` and the next logout where the installer is unavailable and says so. Restarting the shell from `handaan-update` would close that window for this change and every later one; it was left out because it would restart the bar on every update whether or not any QML moved.

`handaan-apps` no longer installs anything, so the interface changed: `--pending`, `--mark` and `--unmark` are gone, replaced by `handaan-apps-manifest` piped through `jq` and by `handaan-apps-mark`. The app contract itself — `meta`, `packages`, `install.sh`, `update.sh`, `config/` — is untouched, so no app directory has to change.

The Hyprland window rule that floated the old dialog is removed. Window rules do not apply to layer-shell surfaces, so the rule would have matched nothing and left a reader hunting for a window that no longer exists.

One answer now serves the installer, `handaan-pending`, and the bar's Updates indicator through it. That closed a real bug rather than only removing duplication: the old check tested each declared package against `pacman -Qq`, which does not resolve virtual packages, so an app declaring a provided name — `sh`, `java-runtime` — could never report installed however many times it was installed successfully. The manifest uses `pacman -T`, which resolves provides and version constraints the way pacman itself does.

An install started from a TTY still works with no session running, because `handaan-apps-install` neither opens a window nor needs one.
