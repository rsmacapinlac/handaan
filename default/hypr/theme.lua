-- Colours taken from the wallpaper
-- See https://wiki.hypr.land/Configuring/Basics/Variables/
--
-- The palette is not configuration. handaan-wallpaper-set derives it from the
-- current wallpaper and writes $HANDAAN_STATE/theme/colors.json; this module
-- reads that file, falling back key by key to default/theme/fallback.json, so
-- a machine that has never set a wallpaper still starts themed.
--
-- look.lua calls apply() at load, and handaan-wallpaper-set calls it again through
-- `hyprctl eval` after writing a new palette -- eval runs in this same Lua state,
-- so the running session recolours without a reload. Anything set here in your
-- own conf modules is therefore overwritten on the next wallpaper change.

local M = {}

local handaan = os.getenv("HANDAAN_PATH") or (os.getenv("HOME") .. "/.local/share/handaan")
local state   = os.getenv("HANDAAN_STATE") or (os.getenv("HOME") .. "/.local/state/handaan")

-- Both files are flat {"name": "rrggbb"} objects written by handaan, so a
-- pattern is enough; Hyprland's Lua carries no JSON library.
local function read_palette(path, into)
    local file = io.open(path, "r")
    if not file then
        return
    end
    local text = file:read("a")
    file:close()
    for name, hex in text:gmatch('"([%w_]+)"%s*:%s*"#?(%x%x%x%x%x%x)"') do
        into[name] = "rgb(" .. hex .. ")"
    end
end

function M.palette()
    local c = {}
    read_palette(handaan .. "/default/theme/fallback.json", c)
    read_palette(state .. "/theme/colors.json", c)
    return c
end

function M.apply()
    local c = M.palette()
    hl.config({
        general = {
            col = {
                active_border   = { colors = { c.accent, c.accentAlt }, angle = 45 },
                inactive_border = c.surface,
            },
        },
    })
end

return M
