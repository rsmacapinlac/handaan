-- Window rules
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Ignore maximize requests from apps
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Blur behind the Quickshell bar, whose background is translucent
-- (Theme.barSurface). Matched by the namespace Ui/Bar.qml sets, so the
-- shell's other surfaces -- tooltips, the installer -- are unaffected. The bar
-- reserves its strip, so what blurs behind it is normally the wallpaper.
hl.layer_rule({
    name  = "blur-quickshell-bar",
    match = { namespace = "^quickshell-bar$" },

    blur = true,
})

-- Float pulsemixer (launched via kitty --class pulsemixer) centred on whichever
-- monitor the flyout opens on. `center` is used instead of an absolute `move`
-- because coordinates are monitor-local: a position measured on the ultrawide
-- puts the window entirely off the right edge of the 1280-logical-px laptop
-- panel, where the flyout looks like it simply never opened.
--
-- Sizing stays with kitty (remember_window_size=no + initial_window_width/height
-- in the kitty config) since kitty re-asserts its own geometry after mapping,
-- which silently defeats a Hyprland windowrule `size`.
hl.window_rule({
    name  = "float-pulsemixer",
    match = { class = "^pulsemixer$" },

    float  = true,
    center = true,
})
