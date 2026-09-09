# Decisions

Architecture decision records for this repository. Each file captures one choice: what forced it, and what was chosen. A record is the current answer; [`adrs/CHANGELOG.md`](adrs/CHANGELOG.md) records how the answers have moved.

These exist because the reasoning behind a config is the part that evaporates. The config itself is in git and speaks for itself; *why it is not the obvious alternative* is not, and that is what gets re-litigated at 1am during a rebuild — or quietly undone by an agent that only sees the current state.

## Conventions

- A record in the adr folder is the definitive decision.
- One decision per file in [`adrs/`](adrs), named `NNNN-kebab-slug.md`, numbered in the order written.
- Format uses the [`template.md`](template.md).
- An edit that modifies a decision requires an update in [`adrs/CHANGELOG.md`](adrs/CHANGELOG.md).
- Write one when a choice is non-obvious, was contested, or would look like a mistake to someone arriving cold. Not for defaults nobody questioned.
- A title names the requirement, not the mechanism — 0001 is about recovering from a bad upgrade, not about GRUB. That keeps the record honest, but it means the mechanism is in neither the title nor the filename: find a record with `grep -rl GRUB adrs/`, not by scanning `ls`.

## Candidates

Decisions already made and living as prose in `README.md`, `AGENTS.md`, or `docs/`, not yet written up here:

**Install**
- Install the base system from saved archinstall profiles, `Minimal` with an empty package list

**Session**
- uwsm wrapping `start-hyprland`, so packaged user units actually start
- Packaged systemd user units rather than `exec-once`, for hypridle, hyprpaper, mako and hyprpolkitagent
- Quickshell gets a unit of its own, with `QS_DISABLE_FILE_WATCHER=1` set on it
- Suspend on lid close left to systemd-logind's own defaults, with clamshell handled in `handaan-lid-switch` by dropping the panel out of the layout — see [Monitors](../monitors.md)

**Compositor and bar**
- Hyprland configured in Lua, while hyprlock/hypridle/hyprpaper stay hyprlang
- Quickshell replaces Waybar; Waybar stays installed but un-enabled
- Bar layout declared in QML rather than read from a config file
- `qs.*` module imports with an explicit `qmldir`, never relative paths
- Per-monitor widget state via `BarWidget.screen`, never a session-wide global

**Theming**
- One generated palette: `default/themed/mocha.json` into three syntaxes
- `Colors` (raw palette) and `Theme` (semantic roles) kept separate

**Repository and tooling**
- Public repo plus private companion; the override mechanism was rebuilt on the copy model after the move off `rcm` (see 0003)
- `~/.ssh` deliberately unmanaged; the bootstrap creates no secrets
- Account-bound services kept out of the bootstrap
- mise owns portable developer tools; `config/mise/config.toml` stays untracked
- Commands are `bin/handaan-<verb>` carrying their own `# handaan:summary=` metadata
- Passwords retrieved through `pass`, never stored in a config file
- Citrix `icaclient` from the AUR, with a manual version bump expected

**Testing**
- Rehearse the bootstrap in a disposable VM, driven by simulated keystrokes
