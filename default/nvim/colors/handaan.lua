-- handaan: Neovim's colours, taken from the wallpaper.
--
-- Not rendered from a template like the other terminal apps: Neovim can read
-- the palette itself, the way Hyprland and the shell do, falling back key by
-- key to default/theme/fallback.json. And it watches the palette, so a running
-- Neovim recolours when the wallpaper changes. To use it:
--
--   vim.opt.rtp:append((vim.env.HANDAAN_PATH or vim.env.HOME .. "/.local/share/handaan") .. "/default/nvim")
--   vim.cmd.colorscheme("handaan")
--
-- Syntax is coloured from the terminal's hues rather than the accents, so code
-- looks the same in Neovim as in anything else printing to the terminal, and
-- the accent is kept for what is selected or current. See ADR 0009.

local handaan = vim.env.HANDAAN_PATH or (vim.env.HOME .. "/.local/share/handaan")
local state = vim.env.HANDAAN_STATE
  or ((vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/handaan")
local theme_dir = state .. "/theme"

local function read(path)
  local file = io.open(path, "r")
  if not file then
    return {}
  end
  local ok, data = pcall(vim.json.decode, file:read("a"))
  file:close()
  return (ok and type(data) == "table") and data or {}
end

local c = {}
for _, source in ipairs({ read(handaan .. "/default/theme/fallback.json"), read(theme_dir .. "/colors.json") }) do
  for name, hex in pairs(source) do
    if type(hex) == "string" and hex:match("^%x%x%x%x%x%x$") then
      c[name] = "#" .. hex
    end
  end
end

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.background = "dark"
vim.g.colors_name = "handaan"

local function hl(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

-- ------------------------------------------------------------------- editor
hl("Normal", { fg = c.text, bg = c.background })
hl("NormalNC", { link = "Normal" })
hl("NormalFloat", { fg = c.text, bg = c.surface })
hl("FloatBorder", { fg = c.border, bg = c.surface })
hl("FloatTitle", { fg = c.accent, bg = c.surface, bold = true })
hl("WinSeparator", { fg = c.border })
hl("EndOfBuffer", { fg = c.background })
hl("NonText", { fg = c.border })
hl("Whitespace", { fg = c.surfaceHover })
hl("SpecialKey", { fg = c.border })
hl("Conceal", { fg = c.textMuted })

hl("Cursor", { fg = c.background, bg = c.accent })
hl("lCursor", { link = "Cursor" })
hl("TermCursor", { link = "Cursor" })
hl("CursorLine", { bg = c.surface })
hl("CursorColumn", { link = "CursorLine" })
hl("ColorColumn", { bg = c.surface })
hl("LineNr", { fg = c.border })
hl("CursorLineNr", { fg = c.accent, bold = true })
hl("SignColumn", { fg = c.textMuted })
hl("FoldColumn", { fg = c.border })
hl("Folded", { fg = c.textMuted, bg = c.surface })

hl("Visual", { bg = c.surfaceHover })
hl("VisualNOS", { link = "Visual" })
hl("Search", { fg = c.background, bg = c.accentAlt })
hl("IncSearch", { fg = c.background, bg = c.accent })
hl("CurSearch", { link = "IncSearch" })
hl("Substitute", { fg = c.background, bg = c.warning })
hl("MatchParen", { fg = c.accent, bold = true, underline = true })

hl("StatusLine", { fg = c.text, bg = c.surface })
hl("StatusLineNC", { fg = c.textMuted, bg = c.backgroundDeep })
hl("TabLine", { fg = c.textMuted, bg = c.surface })
hl("TabLineFill", { bg = c.backgroundDeep })
hl("TabLineSel", { fg = c.background, bg = c.accent, bold = true })
hl("WinBar", { fg = c.text })
hl("WinBarNC", { fg = c.textMuted })

hl("Pmenu", { fg = c.text, bg = c.surface })
hl("PmenuSel", { fg = c.background, bg = c.accent })
hl("PmenuSbar", { bg = c.surface })
hl("PmenuThumb", { bg = c.border })
hl("WildMenu", { link = "PmenuSel" })

hl("Title", { fg = c.accent, bold = true })
hl("Directory", { fg = c.ansiBlue })
hl("Question", { fg = c.accentAlt })
hl("MoreMsg", { fg = c.accentAlt })
hl("ModeMsg", { fg = c.text, bold = true })
hl("ErrorMsg", { fg = c.critical, bold = true })
hl("WarningMsg", { fg = c.warning })

hl("SpellBad", { sp = c.critical, undercurl = true })
hl("SpellCap", { sp = c.warning, undercurl = true })
hl("SpellLocal", { sp = c.ansiCyan, undercurl = true })
hl("SpellRare", { sp = c.ansiMagenta, undercurl = true })

-- ------------------------------------------------------------------- syntax
-- Tree-sitter's @groups link to these by default, so they colour both.
hl("Comment", { fg = c.textMuted, italic = true })
hl("Constant", { fg = c.ansiYellow })
hl("String", { fg = c.ansiGreen })
hl("Character", { link = "String" })
hl("Number", { fg = c.ansiYellow })
hl("Boolean", { fg = c.ansiYellow })
hl("Float", { link = "Number" })
hl("Identifier", { fg = c.text })
hl("Function", { fg = c.ansiBlue })
hl("Statement", { fg = c.ansiMagenta })
hl("Keyword", { fg = c.ansiMagenta })
hl("Conditional", { link = "Keyword" })
hl("Repeat", { link = "Keyword" })
hl("Label", { fg = c.ansiCyan })
hl("Exception", { link = "Keyword" })
hl("Operator", { fg = c.ansiCyan })
hl("PreProc", { fg = c.ansiMagenta })
hl("Include", { link = "PreProc" })
hl("Define", { link = "PreProc" })
hl("Macro", { link = "PreProc" })
hl("Type", { fg = c.ansiCyan })
hl("StorageClass", { link = "Keyword" })
hl("Structure", { link = "Type" })
hl("Typedef", { link = "Type" })
hl("Special", { fg = c.accentAlt })
hl("SpecialChar", { fg = c.ansiCyan })
hl("Tag", { fg = c.ansiBlue })
hl("Delimiter", { fg = c.textMuted })
hl("SpecialComment", { fg = c.textMuted, bold = true })
hl("Debug", { fg = c.warning })
hl("Underlined", { underline = true })
hl("Error", { fg = c.critical })
hl("Todo", { fg = c.background, bg = c.warning, bold = true })

hl("@variable", { fg = c.text })
hl("@variable.builtin", { fg = c.ansiRed })
hl("@variable.parameter", { fg = c.ansiWhite })
hl("@variable.member", { fg = c.ansiWhite })
hl("@property", { link = "@variable.member" })
hl("@constructor", { fg = c.ansiCyan })
hl("@module", { fg = c.ansiWhite })
hl("@punctuation", { link = "Delimiter" })
hl("@markup.heading", { link = "Title" })
hl("@markup.link", { fg = c.accentAlt, underline = true })
hl("@markup.raw", { fg = c.ansiGreen })
hl("@markup.strong", { bold = true })
hl("@markup.italic", { italic = true })

-- -------------------------------------------------------------- diagnostics
hl("DiagnosticError", { fg = c.critical })
hl("DiagnosticWarn", { fg = c.warning })
hl("DiagnosticInfo", { fg = c.ansiBlue })
hl("DiagnosticHint", { fg = c.ansiCyan })
hl("DiagnosticOk", { fg = c.good })
hl("DiagnosticUnderlineError", { sp = c.critical, undercurl = true })
hl("DiagnosticUnderlineWarn", { sp = c.warning, undercurl = true })
hl("DiagnosticUnderlineInfo", { sp = c.ansiBlue, undercurl = true })
hl("DiagnosticUnderlineHint", { sp = c.ansiCyan, undercurl = true })
hl("LspReferenceText", { bg = c.surfaceHover })
hl("LspReferenceRead", { link = "LspReferenceText" })
hl("LspReferenceWrite", { link = "LspReferenceText" })
hl("LspInlayHint", { fg = c.border, italic = true })

-- --------------------------------------------------------------------- diff
hl("DiffAdd", { bg = c.surface, fg = c.good })
hl("DiffChange", { bg = c.surface })
hl("DiffDelete", { fg = c.critical })
hl("DiffText", { bg = c.surfaceHover, fg = c.warning })
hl("Added", { fg = c.good })
hl("Changed", { fg = c.warning })
hl("Removed", { fg = c.critical })
hl("diffAdded", { link = "Added" })
hl("diffChanged", { link = "Changed" })
hl("diffRemoved", { link = "Removed" })
hl("GitSignsAdd", { link = "Added" })
hl("GitSignsChange", { link = "Changed" })
hl("GitSignsDelete", { link = "Removed" })

-- ----------------------------------------------------------------- terminal
-- :terminal buffers get the same sixteen as kitty.
local ansi = {
  c.ansiBlack, c.ansiRed, c.ansiGreen, c.ansiYellow, c.ansiBlue, c.ansiMagenta, c.ansiCyan, c.ansiWhite,
  c.ansiBrightBlack, c.ansiRed, c.ansiGreen, c.ansiYellow, c.ansiBlue, c.ansiMagenta, c.ansiCyan, c.ansiBrightWhite,
}
for i, hex in ipairs(ansi) do
  vim.g["terminal_color_" .. (i - 1)] = hex
end

-- -------------------------------------------------------------------- watch
-- handaan-wallpaper-set renames a new colors.json into place, which fires this.
-- Loaded again only while handaan is still the colorscheme, so switching away
-- is not undone by the next wallpaper. One watcher per Neovim: sourcing this
-- file again (every :colorscheme handaan) must not add another, and the handle
-- is kept in package.loaded so nothing collects it.
if not package.loaded["handaan.theme_watch"] and vim.uv.fs_stat(theme_dir) then
  local watch = vim.uv.new_fs_event()
  if watch then
    local ok = watch:start(theme_dir, {}, vim.schedule_wrap(function(err, file)
      if not err and file == "colors.json" and vim.g.colors_name == "handaan" then
        vim.cmd.colorscheme("handaan")
      end
    end))
    if ok then
      package.loaded["handaan.theme_watch"] = watch
    end
  end
end
