-- Monitors: what handaan does when the set of screens changes.
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- Rules -- modes, positions, scales -- are deliberately not here. Those describe
-- one machine's hardware, so they are yours, in ~/.config/hypr/conf/monitors.lua.
-- What is left is mechanism, and mechanism has to be handaan's: every line below
-- is a fix that must be able to reach a machine that is already installed. See
-- docs/decisions/adrs/0003-install-into-a-single-owned-tree.md.
--
-- Required from default/hypr/autostart.lua rather than from your hyprland.lua,
-- for that same reason -- a default reached only by a line in a file under
-- ~/.config could never arrive on a machine already carrying that file.

local handaan = os.getenv("HANDAAN_PATH") or (os.getenv("HOME") .. "/.local/share/handaan")

local lid_switch = handaan .. "/bin/handaan-lid-switch"
local recover    = handaan .. "/bin/handaan-monitor-recover"

-- The lid binds in binds.lua cover the lid moving, but pulling the dock while
-- the lid is already shut fires no lid event -- and leaving the panel disabled
-- there would leave the session with no display at all. This is what brings it
-- back. It also runs at session start, where nothing fires a lid event either:
-- booting with the lid already shut and a monitor attached is clamshell too.
local function sync_lid_state()
    hl.exec_cmd(lid_switch .. " sync")
end

-- A monitor that was powered off when Hyprland read its EDID answers with a
-- partial one carrying no modes, so the output comes up at 0x0 and the screen
-- stays black. Switching it on afterwards fires nothing, and only a reload
-- re-reads the EDID. See handaan-monitor-recover for why this needs a loop.
local function recover_modeless()
    hl.exec_cmd(recover)
end

hl.on("hyprland.start", function()
    sync_lid_state()
    recover_modeless()
end)

hl.on("monitor.added", function()
    sync_lid_state()
    recover_modeless()
end)

hl.on("monitor.removed", sync_lid_state)

-- A reload is not a neutral event for the panel. lid-switch disables the internal
-- output at runtime with `hyprctl eval`, and a reload re-reads a config that says
-- no such thing -- so every reload silently un-clamshells the machine, lid still
-- shut. That is the same mechanism lid-switch deliberately uses to bring the
-- panel back, which is why it cannot simply be avoided: it has to be reconciled
-- after the fact. Nothing else fires here, so a `handaan-refresh-config`, a
-- manual reload, or Hyprland's own autoreload on a config write would otherwise
-- leave the panel on with the lid closed until the next lid or hotplug event.
--
-- No loop: reconciling to disabled uses `hyprctl eval` and reloads nothing, and
-- reconciling to enabled finds the state already matching and returns early.
-- `sync` also takes a non-blocking flock, so a re-entrant call exits.
--
-- recover's own reload lands here too. Its lock makes that a no-op while a
-- recovery loop is already running, which is what stops the two chasing each
-- other.
hl.on("config.reloaded", function()
    sync_lid_state()
    recover_modeless()
end)
