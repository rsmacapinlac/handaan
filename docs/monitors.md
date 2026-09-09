# Monitors

How handaan decides what a screen does, and what configuration you own.  

Reference:
 - [Configuration is modular](standards/configuration-is-modular.md)

| | what it holds | who owns it |
|---|---|---|
| `~/.config/hypr/conf/monitors.lua` | **Rules.** Modes, positions, scales, transforms, which outputs to disable. | You. Seeded once from `config/`, never overwritten. |
| `~/.config/hypr/conf/local.lua` | Rules too, for one machine — anything carrying a serial number. | You, untracked. |
| `default/hypr/monitors.lua` | **Mechanism.** What happens when the set of screens changes. | handaan. Replaced by `git pull`. |

## What handaan ships as a rule

```lua
local handaan_monitor_scale = "auto"
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = handaan_monitor_scale })

local handaan_gdk_scale = 1
hl.env("GDK_SCALE", tostring(handaan_gdk_scale))
```
### The two scales are different things

- **`handaan_monitor_scale`** is Hyprland's scale for the output. 
- **`handaan_gdk_scale`** is `GDK_SCALE`, the factor GTK draws its own UI at.

## Changing the scale

```bash
handaan monitor-scale          # what the focused monitor is at
handaan monitor-scale up       # next step up the ladder
handaan monitor-scale 1.6      # a specific value
```

Hyprland refuses a scale where the mode does not divide into whole logical pixels, counted in 1/120ths, so a requested value is rounded **up** to the nearest one that does — `1.5` on a 2560x1080 panel becomes `1.6`, and the command says so. The gcd derivation for those clean values is adapted from Omarchy's `omarchy-hyprland-monitor-scaling`.

It applies the change with `hyprctl eval` and then writes the monitor-scale knob back into your `conf/monitors.lua`, so the scale survives a reboot — **but only when the catch-all governs a single output.** That caveat is the whole subtlety: the knob is the catch-all's scale, and the catch-all applies to every output it claims. On a two-monitor machine with no named rules, persisting a change made to the focused screen would move the other one too on the next reload. So the command counts what the catch-all governs, and where it is more than one it leaves the runtime change standing alone and prints the named rule to add instead. It leaves `handaan_gdk_scale` alone — that is an XWayland knob which does not track the monitor scale here, for the reason above. When it does write, that makes it **the only handaan command that writes to a file under `~/.config` outside `handaan-refresh-config`** — which is acceptable only because you asked it to, by name, for one setting. It edits that one `local` line and nothing else: if you have given the monitor a named rule with its own scale, that rule wins on the next reload and the command tells you rather than rewriting it.

## Events 

`default/hypr/monitors.lua` subscribes to four Hyprland events. It holds no rules at all.

| event | what runs | why |
|---|---|---|
| `hyprland.start` | `handaan-lid-switch sync`, `handaan-monitor-recover` | Booting with the lid already shut and a monitor attached is clamshell, and nothing fires a lid event for it. |
| `monitor.added` | both, as above | |
| `monitor.removed` | `handaan-lid-switch sync` | Pulling the dock while the lid is shut fires no lid event, and leaving the panel disabled there leaves the session with no display at all. |
| `config.reloaded` | `handaan-lid-switch sync`, `handaan-monitor-recover` | A reload discards the runtime disable that clamshell relies on, so every reload un-clamshells the machine with the lid still shut. It also lands in the same blank state as boot when a monitor is unpowered. |

### The blank screen at boot

`bin/handaan-monitor-recover` exists for one failure that has no other way out. A monitor that was powered off when Hyprland read its EDID answers with a partial one carrying **no video modes**. Hyprland enables the output anyway, at 0x0, and the screen stays black.

Nothing recovers that on its own: switching the monitor on afterwards fires no DRM hotplug, forcing a re-probe needs root, and only `hyprctl reload` makes Hyprland read the EDID again. So the machine sits blank indefinitely with no error anywhere to explain it.

Hence a loop rather than a check — reload, wait, look again, backing off 3s to 60s because the wait can be hours. It exits the moment nothing is modeless, which is what happens on essentially every invocation. A `flock` keeps one loop at a time, which is also what stops its own reload re-triggering it through `config.reloaded`.

### Clamshell

Lid handling is [`bin/handaan-lid-switch`](../bin/handaan-lid-switch).

## Testing 

`monitors.lua` is Lua, so the cheap check is the same one [Testing the build scripts](testing-build-scripts.md#local-checks-before-the-vm) already runs:

```bash
luac -p config/hypr/conf/*.lua default/hypr/*.lua
bash -n bin/handaan-monitor-*
```

Neither catches a rule that parses and does nothing, which is the usual failure. For that, use `hyprctl monitors all` before and after a `hyprctl reload`.

`handaan-monitor-recover` is safe to run by hand: on a healthy session it reads `hyprctl monitors all`, finds nothing modeless, and exits without reloading.
