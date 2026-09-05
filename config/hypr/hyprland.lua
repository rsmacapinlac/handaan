-- Hyprland configuration.
-- See https://wiki.hypr.land/Configuring/Start/
--
-- Reference for the hl.* API lives at /usr/share/hypr/stubs/hl.meta.lua and the
-- shipped example config at /usr/share/hypr/hyprland.lua.
--
-- This file is yours. It was seeded from handaan's config/ tree at install time
-- and is never overwritten by an update -- take a newer version deliberately
-- with `handaan-refresh-config hypr/hyprland.lua`.
--
-- The handaan defaults below are *not* yours: they are read live out of
-- $HANDAAN_PATH/default/hypr/, so a `git pull` updates them. Do not edit them
-- in place. To change one, override it in your own modules further down --
-- Hyprland applies configuration in load order, so the last writer wins.
--
-- hyprlang has `source =` for this; Lua does not, so the defaults are reached
-- by putting default/ on package.path and requiring them as `hypr.*`. User
-- modules stay `conf.*` and resolve out of ~/.config/hypr/ as before, which is
-- what keeps the two sets of names from colliding.

local handaan = os.getenv("HANDAAN_PATH") or (os.getenv("HOME") .. "/.local/share/handaan")
package.path = handaan .. "/default/?.lua;" .. package.path

-- handaan defaults
require("hypr.env")
require("hypr.autostart")
require("hypr.look")
require("hypr.input")
require("hypr.binds")
require("hypr.rules")

-- Yours. These load last, so anything set here wins.
require("conf.monitors")

-- conf/local.lua is untracked scratch space for one machine. Optional on
-- purpose: pcall keeps a missing file from taking the whole session down.
pcall(require, "conf.local")
