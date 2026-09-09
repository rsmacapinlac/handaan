-- Monitors
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- This file is yours. handaan ships one catch-all rule and two knobs, because
-- it cannot know what is plugged into your machine. Add rules for the screens
-- you actually own below -- or in conf/local.lua, which is untracked, if the
-- rule carries a serial number or anything else particular to one machine.
--
-- What is attached, and which modes each output offers:
--
--     hyprctl monitors all

-- Hyprland's own scale for the output. It sizes everything Wayland-native,
-- accepts fractions (1.25, 1.6), and applies the moment it is set. "auto" lets
-- Hyprland pick per display, which is the right answer until it is not --
-- `handaan-monitor-scale up` writes a number back into this line.
local handaan_monitor_scale = "auto"

-- The catch-all. It claims every output no named rule has taken, so it is what
-- a screen handaan has never seen gets -- which is the point. Keep it that way:
-- a named rule for `eDP-1` would apply its mode and scale to every laptop panel
-- in existence, and the catch-all would never see the panel at all.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = handaan_monitor_scale,
})

-- GDK_SCALE is the factor GTK draws its own UI at. Two things about it, both
-- measured rather than taken from the documentation:
--
--   * It is parsed as an integer. "1.25" and "1.9" both come out as 1; only 2
--     gives 2. There is no way to ask for 1.25 here.
--   * It does nothing for Wayland-native GTK apps. Those take their scale from
--     the compositor, so the monitor scale above already reaches them. This
--     applies to XWayland apps and nothing else.
--
-- So it is the XWayland knob, and 1 is right for handaan as it stands, because
-- handaan does not set `xwayland:force_zero_scaling`. Hyprland scales XWayland
-- surfaces itself, so they are already the size the monitor scale asks for --
-- soft rather than crisp, but correct. Raising this would scale them a second
-- time on top of that. Omarchy sets that option and pairs it with GDK_SCALE 2,
-- which trades softness for XWayland windows sized by an integer; see
-- docs/monitors.md before taking that route on a 1.25 panel.
--
-- A change here only reaches an application when it restarts.
local handaan_gdk_scale = 1
hl.env("GDK_SCALE", tostring(handaan_gdk_scale))

-- Cursor size is a handaan default (default/hypr/env.lua, 24 -- sized for scale
-- 1). This file loads after that one, so a hidpi panel can raise it here:
--
-- hl.env("XCURSOR_SIZE", "36")
-- hl.env("HYPRCURSOR_SIZE", "36")

-- Examples. A named rule beats the catch-all above, whatever the order.
--
-- One output pinned to a mode, placed, and scaled:
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })
--
-- By description rather than connector, for a monitor that moves between ports.
-- `hyprctl monitors all` prints the string; the trailing serial makes it one
-- machine's rule, so prefer conf/local.lua for it:
-- hl.monitor({ output = "desc:LG Electronics LG ULTRAWIDE", mode = "preferred", position = "auto", scale = 1 })
--
-- Turned on its side (transform 1 = 90 degrees, 3 = 270):
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
--
-- A ghost output, which some docks and Thunderbolt displays advertise:
-- hl.monitor({ output = "DP-3", disabled = true })
