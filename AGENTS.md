You are a coding agent that is an expert in managing dotfiles and application configuration.

## What you must read

Before starting work, read [README.md](README.md) and **every file under [`docs/`](docs/)**:

```bash
find docs -name '*.md'   # includes docs/standards/, docs/decisions/ and the records under adrs/
```

Read what that command returns. The standards under [`docs/standards/`](docs/standards/README.md) are binding rather than background; this file covers only what is true because an agent is doing the work.

Then, in the work itself:

- Understand the application config file and where it should be placed.
- Adhere to the standards in [`docs/standards/`](docs/standards/README.md) and the shape rules in [`docs/code-style.md`](docs/code-style.md).

## The single most important rule about layout

**Decide which tree a file belongs in before you write it**, because the answer decides who is allowed to change it afterwards:

- **`default/`** is handaan's, read live out of `$HANDAAN_PATH`. A `git pull` replaces it. Never write a machine-specific value here.
- **`config/`** seeds `~/.config` once at install and is never copied again. Editing a file here does **not** change an installed machine — the user's copy already exists and wins.
- **`~/.config/`** is the user's. Nothing in this repository may overwrite it outside `handaan-refresh-config`.

That last point has a consequence agents get wrong: **changing a file under `config/` does nothing for an existing machine.** If a change has to reach a machine that is already installed, it needs a migration as well. See [0004](docs/decisions/adrs/0004-apply-changes-to-installed-machines.md).

Never hardcode `~/.local/share/handaan`. Use `$HANDAAN_PATH`, or in Lua `os.getenv("HANDAAN_PATH")` with the same fallback the existing modules use. The indirection is what keeps the tree relocatable.

## Validation guidelines

There is no single project-wide test suite. Validate by file type, using the checks in [`docs/testing-build-scripts.md`](docs/testing-build-scripts.md#local-checks-before-the-vm). That file also names the traps a syntax-only check will not catch — Hyprland's silently failing binds and rules among them.

Running `hyprctl reload` touches the live session, so only do it when asked.

Avoid running the installer or `handaan-update` unless explicitly requested; they install packages, alter services, and may require sudo.

## Conventions to follow

- Code shape — shebangs, strict mode, indentation, quoting, the log helpers, and the generated palette files that must never be hand-edited — is [`docs/code-style.md`](docs/code-style.md). Read it before editing. "Match the file you are in" outranks everything else in it.
- Markdown prose is not hard-wrapped; let the editor wrap it. Tables and code blocks carry their own shape. If you find an existing file under `docs/`, confirm before applying this rule.
- Installer steps are small files doing one thing, grouped by phase under `install/<phase>/` and listed in that phase's `all.sh`. Add a file and a line; never grow a function inside `install.sh`.
- Package lists are data, in `install/*.packages`. Comments and blank lines are stripped, so a list can explain why something is on it.
- User-facing commands are `bin/handaan-<group>-<verb>` and declare their own `# handaan:summary=` line, which is what makes them show up in `handaan`.
- Quickshell is one long-running process (`default/quickshell/shell.qml`). Singletons live in `Commons/`, the shell's own surfaces and shared chrome in `Ui/` (`Bar`, `Installer`, `BarWidget`, `Tooltip`), bar widgets in `modules/`. Every shared directory carries a `qmldir` declaring `module qs.<Dir>`, and is imported as `qs.<Dir>`. **Never reach a singleton by relative path** -- a `pragma Singleton` imported that way is instantiated once per importing file, so each consumer silently gets its own empty copy. Only a type in a declared module is process-wide.
- Quickshell service singletons (`UPower`, `Pipewire`) connect lazily: fields read empty until a QML *binding* reads them, because the read is what opens the D-Bus connection. Use declarative bindings, not one-shot reads in `Component.onCompleted`.
- The bar is instantiated once per monitor, so a widget answering anything about "this screen" must use its injected `BarWidget.screen`, never a global. `Hyprland.focusedWorkspace` and `Hyprland.focusedMonitor` are session-wide: every copy of a widget reads the same value and every bar shows the same answer. The per-monitor form is `Hyprland.monitorFor(screen).activeWorkspace`.
- A surface that is summoned -- a dialog, an overlay -- is loaded on demand, so it cannot be what receives the IPC call asking it to appear: a type that is not loaded does not exist to be called. Put the IPC target and the open state on an always-resident singleton and have the surface bind to it, as `Commons/AppCatalog.qml` does for `Ui/Installer.qml`. The two must not share a name -- a type sharing a name with a singleton imported into it shadows that singleton silently, the same trap as `Palette` below.
- Adding any QML type means restarting the shell before it exists: the type registry is built once at launch, and `QS_DISABLE_FILE_WATCHER=1` on the unit means no reload happens on its own. `systemctl --user restart quickshell.service`. This is not a migration -- see [0006](docs/decisions/adrs/0006-present-handaan-dialogs-as-part-of-the-desktop.md).
- `default/quickshell/Commons/Colors.qml` is the generated raw palette; `Commons/Theme.qml` maps it to semantic roles. Widgets bind to `Theme`, never to `Colors` directly, so regenerating or swapping the palette never touches widget code. Do not name a singleton `Palette` -- QtQuick defines that type already and wins the lookup silently, leaving every colour `undefined` instead of erroring.
- Document non-obvious setup and operational decisions in `docs/`.
- When proposing a replacement tool or a new dependency, name what it replaces, what the switch costs, and which standard it serves better than the incumbent. The burden of argument sits with the replacement: Waybar is still installed and deliberately left un-enabled beside Quickshell, so the old path stays available until the new one has proven itself.

## Security and privacy

The public tree, the private companion repository, what counts as identity, and the rules that hold either way are in [`docs/standards/privacy-policy.md`](docs/standards/privacy-policy.md). Read it before adding a file. The private repository is deliberately not named anywhere in this tree.

**The private repository now has its own copy-model seed mechanism**, replacing the old `rcm`-ordering trick. It deploys `~/.config` (and a few root dotfiles) the same no-clobber way handaan does. The two trees currently hold disjoint files, so neither one shadows the other today — but check before assuming that stays true, since nothing enforces it. Disjointness is not what keeps them apart in any case: the seed skips a path whose parent is a symlink into another tree, and never deletes, so a repository deploying by symlink survives an installer run whether the trees overlap or not.

## Agent workflow notes

- Before editing, check `git status --short` and avoid overwriting user changes.
- This repository is both the installed system and the working checkout. Treat local modifications as user-owned unless you made them in this session, and never `rm -rf` the tree.
- Technical decisions are recorded in `docs/decisions/adrs/`. Read the relevant record before changing what it covers, and edit that record in place rather than working around it. A record's title names the requirement rather than the mechanism, so the mechanism is in neither the title nor the filename — find one with `grep -rl <thing> docs/decisions/adrs/`, not by listing the directory. Conventions, and the list of decisions not yet written up, are in [`docs/decisions/README.md`](docs/decisions/README.md).
- The documentation under `docs/` is not optional background. Re-read the file covering the area you are about to change, and update it in the same commit when the change makes it wrong.
- If a command may be long-running, interactive, destructive, or require sudo, ask first or use a separate tmux window/pane when instructed.
- Claude Code historically runs in tmux window 1; use other tmux windows for long-running commands when needed.
