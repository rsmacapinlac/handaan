# Hyprland Startup Configuration

This document explains how Hyprland is launched in this system and the rationale behind the startup method choice.

## Overview

Hyprland is launched by the **greetd** display manager through **uwsm**
(Universal Wayland Session Manager), which in turn runs the official
`start-hyprland` wrapper:

```
uwsm start -- start-hyprland
```

uwsm does not replace `start-hyprland` — it wraps it. Both are in play.

Greetd is not installed by the minimal Archinstall profile. After the first
reboot into a TTY, `boot.sh` dispatches to the core `install.sh`
installer, which installs greetd and `uwsm` and enables greetd. The following
reboot enters the user's Hyprland session automatically.

## Startup Method

### Current Configuration

- **Display Manager**: greetd
- **Configuration File**: `/etc/greetd/config.toml`
- **Startup Command**: `uwsm start -- start-hyprland`
- **Provided By**: `uwsm` package, plus `start-hyprland` from the Hyprland package

### Configuration Example

```toml
[terminal]
vt = 1

[default_session]
command = "uwsm start -- start-hyprland"
user = "greeter"

[initial_session]
command = "uwsm start -- start-hyprland"
user = "<your-username>"
```

## Why uwsm

The session is a set of systemd user units, not a pile of orphaned child
processes. Concretely, uwsm activates `graphical-session-pre.target`,
`graphical-session.target` and `xdg-desktop-autostart.target`.

That last point is the whole reason this repo moved to it. Arch packages ship
user units declaring `WantedBy=graphical-session.target`:

`hypridle`, `hyprpaper`, `hyprpolkitagent`

No notification daemon is among them: notifications belong to the Quickshell shell, and a packaged daemon's D-Bus activation would start it the moment anything notified before the shell was up. See [0008](decisions/adrs/0008-notifications-are-part-of-the-desktop-shell.md).

**Without a session manager that target never activates**, so those units are
enabled but never started. This is not theoretical: `hypridle` was enabled and
never ran on this configuration, which meant no idle timeout and no automatic
screen lock, and nothing surfaced an error. The old arrangement worked only
because `conf/autostart.lua` hand-execed a subset of the same programs —
`hypridle` was simply missing from that list.

Running under uwsm means:

- Those four services start and stay supervised, with systemd restart policies.
- The list is maintained by the packages, not by hand in `autostart.lua`.
- `~/.config/autostart/*.desktop` entries are honoured, because
  `xdg-desktop-autostart.target` is activated.
- Session processes die with the session rather than being reparented to init.

### How things get started

There are two mechanisms, and which one applies depends on whether the program
ships a unit.

| Program | Started by |
|---|---|
| `hypridle`, `hyprpaper`, `hyprpolkitagent` | packaged systemd user units, enabled by `install.sh` |
| `quickshell` | our own user unit, enabled by `install.sh`. Also the notification daemon. |
| `nm-applet`, `blueman-applet`, `set_wallpaper` | `conf/autostart.lua`, wrapped in `uwsm-app` |

`conf/autostart.lua` wraps each remaining command in `uwsm-app` so it lands in
its own systemd scope. **Do not exec a unit-backed service from
`autostart.lua`** — that starts a second, unsupervised copy alongside the unit.

`bin/handaan-wallpaper-set` is deliberately systemd-aware for the
same reason: it starts `hyprpaper.service` rather than forking its own copy.

### quickshell: the bar

The status bar is Quickshell, configured in QML under `default/quickshell/` and
started by `default/systemd/user/quickshell.service`. That unit is ours rather
than packaged — Quickshell ships no unit — but it attaches to
`graphical-session.target` exactly like the four above, so it is supervised,
restarts on failure, and logs to the journal:

```bash
systemctl --user status quickshell
journalctl --user -u quickshell -b
```

Two properties of that unit are deliberate:

- **The file watcher is on**, which is Quickshell's default: writing to the QML
  under `default/quickshell` reloads the shell in place, with no restart in the
  iteration loop. The unit sets no `QS_DISABLE_FILE_WATCHER`, and setting it to
  `0` would not undo this — Quickshell tests whether the variable is *set*, not
  what it holds, so turning the watcher off means removing the line rather than
  changing its value.

  It was off until now, and the reason it was is still true: `handaan-update`
  pulls into this very tree, so a reload can land against a half-written config.
  That was traded away deliberately rather than solved. A failed reload keeps
  the generation already running and reports the error instead of tearing the
  session down, the next complete write reloads correctly, and `Restart=on-failure`
  covers the case where it does come apart. If a mid-pull reload ever does leave
  the bar wrong, `systemctl --user restart quickshell.service` is still the
  cure, and it is worth reporting rather than living with.
- A restart is *required*, not merely tidier, after adding a new QML type or
  singleton. Quickshell builds its type registry once at launch; a hot reload
  does not rescan for new registrations, so a newly added singleton fails with
  `ReferenceError: <Name> is not defined` even though the file is valid and in
  place. This is the one case the watcher does not cover, and the one case where
  a reload that appears to do nothing is not a bug.

### Caveat: PATH

uwsm does not inherit an interactive shell's PATH. Commands launched from
`autostart.lua` use absolute paths for anything outside the system `PATH` —
this is a known friction point with custom session scripts.

## Verifying the session

`enabled` is not `running`, and that distinction is what previously hid a
broken idle timeout. Check the target and the processes:

```bash
systemctl --user is-active graphical-session.target    # expect: active
for p in hypridle hyprpaper hyprpolkitagent quickshell; do
  printf '%-18s ' "$p"; pgrep -x "$p" >/dev/null && echo RUNNING || echo "NOT RUNNING"
done
systemctl --user list-units --state=failed             # expect: none
busctl --user status org.freedesktop.Notifications | grep '^Comm='   # expect: Comm=quickshell
```

If `graphical-session.target` is inactive, the session did not come up through
uwsm and every unit above will be silently absent.

## Making Changes

### Modifying the Startup Command

If you need to change how Hyprland starts:

1. **Edit the system configuration:**
   ```bash
   sudo vim /etc/greetd/config.toml
   ```

2. **Update the dotfiles for future installations:**
   ```bash
   vim ~/.local/share/handaan/install.sh
   # Edit the install_greeter() function
   ```

3. **Apply changes (logs you out!):**
   ```bash
   sudo systemctl restart greetd.service
   ```
   Or reboot for cleaner application.

### Testing Changes

After modifying the configuration:

```bash
# Check for startup warnings
journalctl -b | grep -i "hyprland was started without"

# View greetd logs
journalctl -u greetd.service -b

# Check Hyprland is running correctly
hyprctl version
```

## Troubleshooting

### Warning: "Hyprland was started without start-hyprland"

**Symptom**: This warning appears in the logs after Hyprland starts.

**Cause**: Hyprland was launched directly (via `Hyprland` command) or improperly via UWSM (using `uwsm start hyprland` instead of referencing the desktop file).

**Solution**: Ensure `/etc/greetd/config.toml` uses
`command = "uwsm start -- start-hyprland"`

### Startup Fails After Configuration Change

1. **Check greetd logs for errors:**
   ```bash
   sudo journalctl -u greetd.service -n 50
   ```

2. **Verify configuration syntax:**
   ```bash
   sudo cat /etc/greetd/config.toml
   ```

3. **Restore backup if needed:**
   ```bash
   sudo cp /etc/greetd/config.toml.backup /etc/greetd/config.toml
   sudo systemctl restart greetd.service
   ```

4. **Test from TTY:**
   - Press `Ctrl+Alt+F2` to switch to another TTY
   - Login and manually test: `uwsm start -- start-hyprland`
   - Check for error messages

### Environment Variables Not Set

If applications can't find Wayland or have display issues:

```bash
# Verify environment variables are set correctly
echo $WAYLAND_DISPLAY
echo $XDG_SESSION_TYPE
echo $XDG_CURRENT_DESKTOP

# Should output:
# wayland-1 (or similar)
# wayland
# Hyprland
```

If these are missing, the wrapper isn't being used correctly.

## Configuration Files

### System Configuration

**File**: `/etc/greetd/config.toml`
- Controls how greetd launches Hyprland
- Requires sudo to edit
- Changes take effect after restart/relogin

### Dotfiles Setup Script

**File**: `~/.local/share/handaan/install.sh`
- Function: `install_greeter()`
- Automatically generates greetd config during system setup
- Keeps configuration consistent across installations

### Desktop Files

**Standard**: `/usr/share/wayland-sessions/hyprland.desktop`
- Exec: `/usr/bin/start-hyprland`
- Used by display managers for session selection

**UWSM**: `/usr/share/wayland-sessions/hyprland-uwsm.desktop`
- Exec: `uwsm start -e -D Hyprland hyprland.desktop`
- Not used by greetd here: the greetd command invokes `uwsm start` directly
  against `start-hyprland` rather than going through this desktop file.
- Available but not used by default

## References

- [Hyprland Wiki: Master Tutorial](https://wiki.hypr.land/Getting-Started/Master-Tutorial/)
- [Hyprland Wiki: Systemd Startup](https://wiki.hypr.land/Useful-Utilities/Systemd-start/)
- [greetd Documentation](https://man.sr.ht/~kennylevinsen/greetd/)
- [GitHub: Hyprland "started without start-hyprland" Discussion](https://github.com/hyprwm/Hyprland/discussions/12661)
- [GitHub: uwsm vs start-hyprland Discussion](https://github.com/hyprwm/Hyprland/discussions/12805)
- [ArchWiki: greetd](https://wiki.archlinux.org/title/Greetd)
- [ArchWiki: Hyprland](https://wiki.archlinux.org/title/Hyprland)
