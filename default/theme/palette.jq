# matugen's scheme onto handaan's palette names.
#
# Input:  `matugen image --json hex` output, run with good/warning/critical and
#         the terminal's hues as custom colours blended toward the wallpaper.
# Args:   $fallback (the parsed default/theme/fallback.json), $wallpaper.
# Output: the flat {"name": "rrggbb"} object Hyprland and the shell read.
#
# The status colours are what make this more than a lookup. Blended, they sit
# in the wallpaper's palette instead of on top of it -- but a blend can carry a
# status colour out of its hue, and a status colour whose hue has moved no
# longer says what it means. So each is kept only while it is still the colour
# it is meant to be, and otherwise falls back to the fixed one.
#
# Then the accent is checked against them. On a warm wallpaper matugen's accent
# is the same peach as "warning", and no choice of warning fixes that -- Mocha's
# own peach is as close as the blended one. The accent is decoration and the
# status colours are meaning, so it is the accent that gives way: primary stays
# the accent while it stands clear of them, and otherwise the scheme's key
# colour standing furthest from them takes its place. Every accent is still one
# of the wallpaper's own colours.
#
# The terminal's colours (ansi*) follow the status colours' rule. A red in a
# diff has to read as red, so each hue is blended and held to its window like
# good, warning and critical are; red and green are those two, so a failed
# test and a critical notification are one colour. Bright hues are the same as
# normal ones, as Catppuccin's are: only black and white get a brighter step,
# and those come from the scheme's own greys.

def role($name): .colors[$name].dark.color | ltrimstr("#") | ascii_downcase;

def byte: explode | map(if . >= 97 then . - 87 else . - 48 end) | .[0] * 16 + .[1];

# Hue in degrees and HSL saturation, from bare six-digit hex.
def hsl:
    [.[0:2], .[2:4], .[4:6]] | map(byte / 255) as [$r, $g, $b]
    | ([$r, $g, $b] | max) as $max
    | ([$r, $g, $b] | min) as $min
    | ($max - $min) as $d
    | (($max + $min) / 2) as $l
    | {
        hue: (if $d == 0 then 0
              elif $max == $r then (60 * ($g - $b) / $d) | if . < 0 then . + 360 else . end
              elif $max == $g then 60 * (($b - $r) / $d + 2)
              else 60 * (($r - $g) / $d + 4) end),
        saturation: (if $d == 0 then 0 else $d / (1 - ((2 * $l - 1) | fabs)) end)
      };

def hue_distance($a; $b): (($a - $b) | fabs) as $x | if $x > 180 then 360 - $x else $x end;

# A window that may wrap through 0, as red does.
def hue_within($lo; $hi): if $lo <= $hi then . >= $lo and . <= $hi else . >= $lo or . <= $hi end;

# What each status colour has to stay. Wide enough for a blend to move it,
# narrow enough that red never reads as pink and peach never as yellow.
def windows: {
    good: [75, 165], warning: [10, 50], critical: [335, 20],
    ansiYellow: [35, 65], ansiCyan: [160, 195], ansiBlue: [195, 250], ansiMagenta: [280, 335]
};

# A blended colour while it keeps its hue, and the fixed one once it does not.
def held($scheme; $fallback; $name):
    ($scheme | role($name)) as $blended
    | if ($blended | hsl.hue | hue_within(windows[$name][0]; windows[$name][1]))
      then $blended else $fallback[$name] end;

# How far a colour stands from the nearest status colour, in degrees of hue.
# A grey stands apart from everything: it cannot be mistaken for a hue.
def clearance($status):
    (hsl) as $a
    | if $a.saturation < 0.2 then 360
      else [$status[] | hsl as $b | if $b.saturation < 0.2 then 360 else hue_distance($a.hue; $b.hue) end] | min end;

. as $scheme
| (["good", "warning", "critical"]
   | map({ key: ., value: held($scheme; $fallback; .) })
   | from_entries) as $status
| ([role("primary"), role("tertiary"), role("secondary")]) as $keys
| (if ($keys[0] | clearance($status)) >= 35 then $keys[0]
   else $keys | max_by(clearance($status)) end) as $accent
| ([$keys[] | select(. != $accent)][0]) as $accentAlt
| {
    background:     role("surface"),
    backgroundDeep: role("surface_container_lowest"),
    surface:        role("surface_container_high"),
    surfaceHover:   role("surface_container_highest"),
    tint:           role("secondary_container"),
    border:         role("outline_variant"),
    text:           role("on_surface"),
    textMuted:      role("outline"),
    accent:         $accent,
    accentAlt:      $accentAlt
  }
  + $status
  + {
    ansiBlack:       role("surface_container_highest"),
    ansiRed:         $status.critical,
    ansiGreen:       $status.good,
    ansiYellow:      held($scheme; $fallback; "ansiYellow"),
    ansiBlue:        held($scheme; $fallback; "ansiBlue"),
    ansiMagenta:     held($scheme; $fallback; "ansiMagenta"),
    ansiCyan:        held($scheme; $fallback; "ansiCyan"),
    ansiWhite:       role("on_surface_variant"),
    ansiBrightBlack: role("outline"),
    ansiBrightWhite: role("on_surface")
  }
| if all(.[]; test("^[0-9a-f]{6}$")) then . else error("matugen output is missing a role") end
| . + { wallpaper: $wallpaper }
