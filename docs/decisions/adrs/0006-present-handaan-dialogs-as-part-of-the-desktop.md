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
| `default/quickshell/Ui/Installer.qml` | The dialog. A layer-shell surface on the focused monitor, bound to `Theme` and `Style` like every widget: a header with what is waiting and the Update and Install all actions, then the list on the left and the app under the cursor on the right. |
| `default/quickshell/Ui/DialogCard.qml` | The card the installer and the wallpaper picker are drawn on. |
| `bin/handaan-apps-manifest` | Discovery and installed-state, as JSON. The only place that answers "which apps exist, and which are installed". |
| `bin/handaan-apps-install` | Installs named apps. No terminal, no picker, no log. |
| `bin/handaan-apps-terminal` | Opens a terminal for the above, keeps the session log, holds the window open on failure, and sends a desktop notification when the run ends. `--uninstall` does the same for an uninstall, and `--update` for `handaan update -y`. |
| `bin/handaan-apps-mark` | Records an install without performing one. |
| `bin/handaan-apps-uninstall` | Uninstalls named apps. No terminal, no picker, no log. |
| `bin/handaan-apps` | Summons the dialog. Nothing else. |

The flow runs one way. `handaan apps` — or `SUPER+SHIFT+A` — calls `appCatalog open`; the shell runs `handaan-apps-manifest` and renders the result; choosing a row hands that app's name to `handaan-apps-terminal` through `execDetached` and closes. Nothing waits for anything: the install pokes `maintenance refresh` when it finishes, and the dialog re-reads the catalogue every time it opens.

**The run reports its end as a notification.** On success the terminal closes, and everything it printed goes with it — for an uninstall, that includes the app directory still to remove. So `handaan-apps-terminal` sends a notification when the run ends: `Installed tmux`, `handaan updated`, or `Uninstalled beets` with the directory to remove as its body. A failure sends a critical one naming the log, beside the window it holds open. The notification lands in the island's history, where it can be read after the window has gone. A run typed into a terminal sends none, since its output is already in front of you.

The dialog is a launcher rather than a form — type to narrow, arrows to move, `Enter` to install the row under the cursor. Multi-select was dropped because installing one app is the overwhelmingly common case and a checkbox list made it the slowest one, and because a tick that started checked on an already-installed app, and did nothing when cleared, was state with no meaning.

**Above the list, a header says what the machine is waiting on and carries the two actions that act on everything.** On the left is a status line: updates as the bar's Updates indicator counts them, security ones called out, and how many apps are pending. On the right are two buttons:

- **Update** runs `handaan update -y` in a terminal through `handaan-apps-terminal --update`. `-y` is passed because the dialog has already asked twice.
- **Install all** installs the pending apps when there are any. When nothing is pending it becomes **Reinstall all**, over every installed app.

Each asks twice: the first press fills the button, and the status line turns into what the second press will do. Update lives here rather than on the bar's indicator because a click on the bar must be harmless if it was a mistake (see `modules/Updates.qml`). Here, a confirmation is already the convention. The header is reached with `Tab`; `←`/`→` move between its buttons, and `Enter` arms, then runs. The search field keeps the keyboard throughout, so typing anything returns to the list without losing the keystroke.

Beside the list is a pane showing the app under the cursor: its summary, whether it is installed, removed or neither, and what it declares — packages, hooks, the files its `config/` ships — with its actions as buttons. The pane is there because uninstall is in the dialog, and an action that takes things away should show what it takes before it runs. A click on a row selects it rather than acting, and hover does not select at all, because the pointer crosses the list on its way to the pane's buttons and must not change what they act on.

**`Enter` installs and only ever installs. Uninstall is `Ctrl+Delete`, and it asks twice.** The first press arms the row and the pane spells out what will go — whether `uninstall.sh` runs, how many config files, which packages are released. The second press runs it in a terminal through `handaan-apps-terminal --uninstall`. `Enter`, `Esc` or moving the cursor disarms it. A key of its own, rather than a choice offered on `Enter`, is what keeps a stray `Enter` cheap: one too many costs an idempotent reinstall, never the app. Uninstall is offered only for an installed app, and there is no uninstall-all.

An app removed with `handaan apps-uninstall` stays in the list as not installed, and counts as pending, until its directory is deleted from the dotfile repository.

**The installer and the wallpaper picker share one card, `Ui/DialogCard.qml`:** a 4px accent border and 12px corners, the frame of the rofi launcher, so every list you summon reads as one family. It is a component rather than values each dialog copies, because copying is how the two drifted apart. A dialog sets only its size and contents. The power menu and the notification history are not summoned lists, and keep their quieter 1px frame.

The power menu is the second dialog built this way, and replaced a rofi script that wrote a theme file into `~/.config/rofi` on every run and carried its own copy of Mocha:

| piece | what it is |
|---|---|
| `default/quickshell/Commons/SessionControl.qml` | Singleton. Holds whether the menu is up, lists the five actions and their commands, runs one. Carries the `sessionControl` IPC target. |
| `default/quickshell/Ui/PowerMenu.qml` | The dialog. Same surface, placement and dismissal as the installer: a compact card with a filter field, the actions in a single row, and a status line. |
| `bin/handaan-session` | Toggles the menu. Nothing else. `Ctrl+Alt+Delete` calls it -- the one exception in [0010](0010-reach-handaan-surfaces-with-one-family-of-shortcuts.md). |

Typing filters the row, matching each action's label and a few synonyms (`reboot`, `sleep`, `shutdown`), and the arrows move through it. Lock and suspend act on the first `Enter`; log out, restart and shut down arm on the first and act on the second, because each ends every open window. The text field, the cursor highlight and the armed colour are the installer's own. The armed item turns warning and the status line carries the prompt, since an action's cell is too narrow to. Everything else about the card stays quiet so that the confirmation is the one loud thing on it. Lock asks the shell's own lock screen, `Commons/SessionLock.qml`, for a lock in-process rather than running a command. Because `Ctrl+Alt+Delete` is pressed when something is already wrong, `handaan-session` sends its failure as a desktop notification when there is no terminal to print to. The expanded island carries the same five actions in a row across its bottom, run through `SessionControl.run` with the same confirm rule, so the menu is no longer the only way to them; it stays for the keyboard and for when the bar is not usable. See [The island](../../island/README.md).

The wallpaper picker is the third, and replaced a key that set a random wallpaper with no way to choose one:

| piece | what it is |
|---|---|
| `default/quickshell/Commons/Wallpapers.qml` | Singleton. Reads the list from `handaan-wallpaper-manifest`, holds whether the picker is up and which wallpaper is current, and hands a choice to `handaan-wallpaper-set`. Carries the `wallpapers` IPC target. |
| `default/quickshell/Ui/WallpaperPicker.qml` | The dialog. Same surface and dismissal as the other two: a filter field, a grid of thumbnails with Random first, and a status line naming the one under the cursor. |
| `bin/handaan-wallpaper` | Toggles the picker. Nothing else. `Super+Shift+W` calls it; see [0010](0010-reach-handaan-surfaces-with-one-family-of-shortcuts.md). |

**The installer and the wallpaper picker are one at a time.** Both are lists you summon to choose from, so opening either closes the other, rather than stacking a second exclusive-keyboard surface over the first. They share one slot, `default/quickshell/Commons/Summoned.qml`: a singleton holding the name of the surface that is up. `AppCatalog.open` claims it for `"installer"`, `Wallpapers.open` for `"wallpapers"`, and each surface's open flag is derived from it (`installerOpen: Summoned.current === "installer"`). Claiming the slot is what closes whichever surface held it, so no surface names another, and a new one joins by claiming a name of its own. Only the holder can release the slot, so a close that arrives late cannot put away a surface that has since taken it. Joining is opt-in. The power menu stays outside: it is reached when something is wrong, and must come up over whatever is already open.

It opens on the wallpaper you have, arrows move in two dimensions, and `Enter` sets. Nothing confirms, because a wallpaper you did not want is one more choice away. It has no scrim, since the wallpaper behind the card is what the thumbnails are being compared against. Choosing a wallpaper is also how the desktop's colours change; see [0007](0007-take-the-desktop-colours-from-the-wallpaper.md).

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
