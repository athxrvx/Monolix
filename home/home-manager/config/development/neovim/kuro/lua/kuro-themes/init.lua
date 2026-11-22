-- ============================================================================
-- kuro-themes -- 11 custom colorschemes generated from ~/.config/kuro/themes
--
-- Palette source : ~/.config/kuro/themes/<name>.toml (read at runtime)
-- Fallback       : embedded copies below (used if the TOMLs are unavailable)
-- ============================================================================

local M = {}

local PALETTE_DIR = vim.fn.expand('~/.config/kuro/themes')
local KURO_CONFIG = vim.fn.expand('~/.config/kuro/kuro.toml')
local STATE_FILE = vim.fn.stdpath('state') .. '/kuro-theme'

local THEMES = {
  'catppuccin',
  'everforest',
  'gruvbox',
  'jellybeans',
  'kanagawa',
  'matte-black',
  'miasma',
  'nord',
  'rose-pine',
  'solitude',
  'tokyo-night',
}

local KNOWN = {}
for _, name in ipairs(THEMES) do
  KNOWN[name] = true
end

-- Embedded fallback palettes -------------------------------------------------
local FALLBACK = {
  catppuccin = {
    name = 'Catppuccin', mode = 'dark', accent = '#89b4fa', selection = '#45475a', muted = '#585b70',
    background = '#1e1e2e', dark_background = '#161622', darker_background = '#101019', lighter_background = '#313244',
    foreground = '#cdd6f4', dark_foreground = '#6c7086', light_foreground = '#bac2de', bright_foreground = '#cdd6f4',
    red = '#f38ba8', yellow = '#f9e2af', orange = '#f6b6ab', green = '#a6e3a1', cyan = '#94e2d5', blue = '#89b4fa',
    magenta = '#f5c2e7', brown = '#7b5b55', bright_red = '#f38ba8', bright_yellow = '#f9e2af',
    bright_green = '#a6e3a1', bright_cyan = '#94e2d5', bright_blue = '#89b4fa', bright_magenta = '#f5c2e7',
  },
  everforest = {
    name = 'Everforest', mode = 'dark', accent = '#7fbbb3', selection = '#3d484d', muted = '#475258',
    background = '#2d353b', dark_background = '#21272c', darker_background = '#181d20', lighter_background = '#343f44',
    foreground = '#d3c6aa', dark_foreground = '#4f585e', light_foreground = '#9da9a0', bright_foreground = '#d3c6aa',
    red = '#e67e80', yellow = '#dbbc7f', orange = '#e09d7f', green = '#a7c080', cyan = '#83c092', blue = '#7fbbb3',
    magenta = '#d699b6', brown = '#704e3f', bright_red = '#e67e80', bright_yellow = '#dbbc7f',
    bright_green = '#a7c080', bright_cyan = '#83c092', bright_blue = '#7fbbb3', bright_magenta = '#d699b6',
  },
  gruvbox = {
    name = 'Gruvbox', mode = 'dark', accent = '#7daea3', selection = '#504945', muted = '#665c54',
    background = '#282828', dark_background = '#1e1e1e', darker_background = '#161616', lighter_background = '#3c3836',
    foreground = '#d4be98', dark_foreground = '#7c6f64', light_foreground = '#bdae93', bright_foreground = '#d4be98',
    red = '#ea6962', yellow = '#d8a657', orange = '#e1875c', green = '#a9b665', cyan = '#89b482', blue = '#7daea3',
    magenta = '#d3869b', brown = '#70432e', bright_red = '#ea6962', bright_yellow = '#d8a657',
    bright_green = '#a9b665', bright_cyan = '#89b482', bright_blue = '#7daea3', bright_magenta = '#d3869b',
  },
  jellybeans = {
    name = 'Jellybeans', mode = 'dark', accent = '#8a694c', selection = '#fad07a', muted = '#888888',
    background = '#0d0d0d', dark_background = '#151515', darker_background = '#0d0d0d', lighter_background = '#303030',
    foreground = '#dedede', dark_foreground = '#888888', light_foreground = '#dedede', bright_foreground = '#ffffff',
    red = '#e27373', yellow = '#ffba7b', orange = '#ffa560', green = '#94b979', cyan = '#00988e', blue = '#97bedc',
    magenta = '#e1c0fa', brown = '#8a694c', bright_red = '#ffa1a1', bright_yellow = '#ffdca0',
    bright_green = '#bddeab', bright_cyan = '#1ab2a8', bright_blue = '#b1d8f6', bright_magenta = '#fbdaff',
    cursor = '#ffa560', cursor_text = '#0d0d0d', url = '#97bedc', inactive_border = '#88888888',
  },
  kanagawa = {
    name = 'Kanagawa', mode = 'dark', accent = '#dcd7ba', selection = '#363646', muted = '#54546d',
    background = '#1f1f28', dark_background = '#17171e', darker_background = '#111116', lighter_background = '#223249',
    foreground = '#dcd7ba', dark_foreground = '#727169', light_foreground = '#c8c093', bright_foreground = '#dcd7ba',
    red = '#c34043', yellow = '#c0a36e', orange = '#c17158', green = '#76946a', cyan = '#6a9589', blue = '#7e9cd8',
    magenta = '#957fb8', brown = '#60382c', bright_red = '#e82424', bright_yellow = '#e6c384',
    bright_green = '#98bb6c', bright_cyan = '#7aa89f', bright_blue = '#7fb4ca', bright_magenta = '#938aa9',
  },
  ['matte-black'] = {
    name = 'Matte Black', mode = 'dark', accent = '#e68e0d', selection = '#2a2a2a', muted = '#333333',
    background = '#121212', dark_background = '#0d0d0d', darker_background = '#090909', lighter_background = '#1e1e1e',
    foreground = '#bebebe', dark_foreground = '#555555', light_foreground = '#8a8a8d', bright_foreground = '#bebebe',
    red = '#d35f5f', yellow = '#b91c1c', orange = '#c63d3d', green = '#ffc107', cyan = '#bebebe', blue = '#e68e0d',
    magenta = '#d35f5f', brown = '#631e1e', bright_red = '#b91c1c', bright_yellow = '#b90a0a',
    bright_green = '#ffc107', bright_cyan = '#eaeaea', bright_blue = '#f59e0b', bright_magenta = '#b91c1c',
  },
  miasma = {
    name = 'Miasma', mode = 'dark', accent = '#78824b', selection = '#383838', muted = '#666666',
    background = '#222222', dark_background = '#191919', darker_background = '#121212', lighter_background = '#2c2c2c',
    foreground = '#c2c2b0', dark_foreground = '#555555', light_foreground = '#8a8a7e', bright_foreground = '#c2c2b0',
    red = '#685742', yellow = '#b36d43', orange = '#8d6242', green = '#5f875f', cyan = '#c9a554', blue = '#78824b',
    magenta = '#bb7744', brown = '#463121', bright_red = '#685742', bright_yellow = '#b36d43',
    bright_green = '#5f875f', bright_cyan = '#c9a554', bright_blue = '#78824b', bright_magenta = '#bb7744',
  },
  nord = {
    name = 'Nord', mode = 'dark', accent = '#81a1c1', selection = '#434c5e', muted = '#4c566a',
    background = '#2e3440', dark_background = '#222730', darker_background = '#191c23', lighter_background = '#3b4252',
    foreground = '#d8dee9', dark_foreground = '#667080', light_foreground = '#adb5c4', bright_foreground = '#d8dee9',
    red = '#bf616a', yellow = '#ebcb8b', orange = '#d5967a', green = '#a3be8c', cyan = '#88c0d0', blue = '#81a1c1',
    magenta = '#b48ead', brown = '#6a4b3d', bright_red = '#bf616a', bright_yellow = '#ebcb8b',
    bright_green = '#a3be8c', bright_cyan = '#8fbcbb', bright_blue = '#81a1c1', bright_magenta = '#b48ead',
  },
  ['rose-pine'] = {
    name = 'Rosé Pine', mode = 'light', accent = '#56949f', selection = '#dfdad9', muted = '#cecacd',
    background = '#faf4ed', dark_background = '#ede7e1', darker_background = '#e1dbd5', lighter_background = '#f2e9e1',
    foreground = '#575279', dark_foreground = '#9893a5', light_foreground = '#6e6a86', bright_foreground = '#575279',
    red = '#b4637a', yellow = '#ea9d34', orange = '#cf8057', green = '#286983', cyan = '#d7827e', blue = '#56949f',
    magenta = '#907aa9', brown = '#67402b', bright_red = '#b4637a', bright_yellow = '#ea9d34',
    bright_green = '#286983', bright_cyan = '#d7827e', bright_blue = '#56949f', bright_magenta = '#907aa9',
  },
  solitude = {
    name = 'Solitude', mode = 'dark', accent = '#798186', selection = '#343d41', muted = '#4b4e55',
    background = '#101315', dark_background = '#0c0e10', darker_background = '#080a0b', lighter_background = '#101315',
    foreground = '#cacccc', dark_foreground = '#4b4e55', light_foreground = '#cbc2be', bright_foreground = '#a5aeb4',
    active_border_color = '#a8adb0', active_tab_background = '#798186',
    red = '#565d60', yellow = '#d9dbdc', green = '#9fa5a9', cyan = '#707070', blue = '#798186', magenta = '#aeaeae',
    bright_red = '#de6145', bright_yellow = '#c9c2b4', bright_green = '#343d41', bright_cyan = '#707070',
    bright_blue = '#5d6367', bright_magenta = '#9a9a9a',
  },
  ['tokyo-night'] = {
    name = 'Tokyo Night', mode = 'dark', accent = '#7aa2f7', selection = '#292e42', muted = '#414868',
    background = '#1a1b26', dark_background = '#13141c', darker_background = '#0e0e14', lighter_background = '#24283b',
    foreground = '#a9b1d6', dark_foreground = '#565f89', light_foreground = '#b4bee6', bright_foreground = '#c0caf5',
    red = '#f7768e', yellow = '#e0af68', orange = '#eb927b', green = '#9ece6a', cyan = '#449dab', blue = '#7aa2f7',
    magenta = '#ad8ee6', brown = '#75493d', bright_red = '#ff7a93', bright_yellow = '#ff9e64',
    bright_green = '#b9f27c', bright_cyan = '#0db9d7', bright_blue = '#7da6ff', bright_magenta = '#bb9af7',
  },
}

-- Helpers --------------------------------------------------------------------
local function parse_toml(path)
  local file = io.open(path, 'r')
  if not file then
    return nil
  end
  local data = {}
  for line in file:lines() do
    line = line:match('^%s*(.-)%s*$')
    if line ~= '' and line:sub(1, 1) ~= '#' then
      local key, value = line:match('^([%w_]+)%s*=%s*(.-)%s*$')
      if key and value then
        local quoted = value:match('^"(.-)"$') or value:match("^'(.-)'$")
        if quoted then
          data[key] = quoted
        elseif value == 'true' then
          data[key] = true
        elseif value == 'false' then
          data[key] = false
        end
      end
    end
  end
  file:close()
  return data
end

local function color(value, fallback)
  if type(value) ~= 'string' then
    return fallback
  end
  local hex = value:match('^#(%x+)$')
  if hex then
    if #hex >= 8 then
      return '#' .. hex:sub(1, 6) -- strip alpha (Neovim only supports #rrggbb)
    end
    if #hex == 6 or #hex == 3 then
      return '#' .. hex
    end
  end
  local rgb = value:match('^rgba?%((%x+)%)')
  if rgb and (#rgb == 6 or #rgb == 8) then
    return '#' .. rgb:sub(1, 6)
  end
  return fallback
end

local function blend(a, b, t)
  local function parts(hex)
    local h = (hex or ''):gsub('#', '')
    if #h == 3 then
      h = h:gsub('(.)(.)(.)', '%1%1%2%2%3%3')
    end
    if #h ~= 6 then
      return 0, 0, 0
    end
    return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
  end

  local ar, ag, ab = parts(a)
  local br, bg, bb = parts(b)
  local function mix(x, y)
    return math.floor(x + (y - x) * t + 0.5)
  end
  return string.format('#%02x%02x%02x', mix(ar, br), mix(ag, bg), mix(ab, bb))
end

local function load_palette(name)
  local from_file = parse_toml(PALETTE_DIR .. '/' .. name .. '.toml')
  local base = from_file or FALLBACK[name] or {}

  local p = {}
  for k, v in pairs(FALLBACK[name] or {}) do
    p[k] = v
  end
  for k, v in pairs(base) do
    p[k] = v
  end

  -- Normalise every colour-like string.
  for k, v in pairs(p) do
    if type(v) == 'string' and (v:sub(1, 1) == '#' or v:lower():match('^rgba?%(')) then
      p[k] = color(v, nil)
    end
  end

  -- Fill gaps (Solitude has no orange / brown, some palettes lack brights).
  p.orange = p.orange or p.accent
  p.brown = p.brown or p.muted
  for _, cname in ipairs({ 'red', 'yellow', 'green', 'cyan', 'blue', 'magenta' }) do
    p['bright_' .. cname] = p['bright_' .. cname] or p[cname]
  end
  p.selection = p.selection or p.muted
  p.lighter_background = p.lighter_background or p.background
  p.dark_background = p.dark_background or p.background
  p.darker_background = p.darker_background or p.dark_background
  p.dark_foreground = p.dark_foreground or p.muted
  p.light_foreground = p.light_foreground or p.foreground
  p.bright_foreground = p.bright_foreground or p.foreground
  p.cursor = p.cursor or p.foreground
  p.cursor_text = p.cursor_text or p.background
  p.inactive_border = p.inactive_border or p.muted
  p.accent = p.accent or p.blue

  return p
end

-- Kuro is the desktop theme source of truth. Read only [theme].scheme so
-- unrelated Kuro settings do not affect the editor palette.
local function kuro_scheme()
  local file = io.open(KURO_CONFIG, 'r')
  if not file then
    return nil
  end

  local in_theme = false
  for line in file:lines() do
    local section = line:match('^%s*%[([^%]]+)%]')
    if section then
      in_theme = section == 'theme'
    elseif in_theme then
      local scheme = line:match("^%s*scheme%s*=%s*['\"]([^'\"]+)['\"]")
      if scheme then
        file:close()
        return KNOWN[scheme] and scheme or nil
      end
    end
  end
  file:close()
  return nil
end

local function watch_kuro_theme()
  local directory = vim.fn.fnamemodify(KURO_CONFIG, ':h')
  local watcher = vim.uv.new_fs_event()
  if not watcher then
    return
  end

  local ok = watcher:start(directory, {}, function(_, filename)
    if filename and filename ~= 'kuro.toml' then
      return
    end
    vim.defer_fn(function()
      local scheme = kuro_scheme()
      if scheme and scheme ~= M.current then
        vim.schedule(function()
          if M.apply(scheme) then
            vim.api.nvim_exec_autocmds('ColorScheme', { modeline = false })
          end
        end)
      end
    end, 120)
  end)
  if ok then
    M._kuro_watcher = watcher
  else
    watcher:close()
  end
end

-- Highlight definitions ------------------------------------------------------
local function define(p)
  local bg = p.background
  local fg = p.foreground
  local dark_bg = p.dark_background
  local darker_bg = p.darker_background
  local light_bg = p.lighter_background
  local dim_fg = p.dark_foreground
  local mid_fg = p.light_foreground
  local bright_fg = p.bright_foreground
  local sel = p.selection
  local muted = p.muted
  local acc = p.accent

  local red, yellow, orange, green = p.red, p.yellow, p.orange, p.green
  local cyan, blue, magenta = p.cyan, p.blue, p.magenta
  local bred, byellow, bgreen = p.bright_red, p.bright_yellow, p.bright_green
  local bcyan, bblue, bmagenta = p.bright_cyan, p.bright_blue, p.bright_magenta

  local subtle = blend(bg, light_bg, 0.55)
  local cursorline = blend(bg, sel, 0.35)
  local colorcol = blend(bg, red, 0.12)
  local pmenu_sel = blend(dark_bg, acc, 0.35)

  -- Structural lines should recede rather than glow.
  local separator = blend(bg, muted, 0.28)
  local separator_soft = blend(bg, muted, 0.18)
  local tree_separator = blend(dark_bg, muted, 0.22)
  local float_border = blend(dark_bg, muted, 0.42)

  -- Tabline is its own surface, clearly separate from the editor background.
  local tabline_bg = blend(darker_bg, muted, 0.10)
  local tab_inactive = blend(tabline_bg, muted, 0.10)
  local tab_active = blend(tabline_bg, acc, 0.28)
  local tabline_border = blend(tabline_bg, acc, 0.45)
  local tab_separator = blend(tabline_bg, muted, 0.30)

  local s = function(group, spec)
    vim.api.nvim_set_hl(0, group, spec)
  end
  local link = function(group, target)
    vim.api.nvim_set_hl(0, group, { link = target })
  end

  -- Core syntax
  s('Normal', { fg = fg, bg = bg })
  s('NormalNC', { fg = mid_fg, bg = bg })
  s('NormalFloat', { fg = fg, bg = dark_bg })
  s('FloatBorder', { fg = float_border, bg = dark_bg })
  s('Comment', { fg = dim_fg, italic = true })
  s('Constant', { fg = orange })
  s('String', { fg = green })
  s('Character', { fg = green })
  s('Number', { fg = orange })
  s('Float', { fg = orange })
  s('Boolean', { fg = orange })
  s('Identifier', { fg = fg })
  s('Function', { fg = blue })
  s('Statement', { fg = magenta })
  s('Conditional', { fg = magenta })
  s('Repeat', { fg = magenta })
  s('Label', { fg = cyan })
  s('Operator', { fg = magenta })
  s('Keyword', { fg = magenta })
  s('Exception', { fg = bred, bold = true })
  s('PreProc', { fg = cyan })
  s('Include', { fg = magenta })
  s('Define', { fg = magenta })
  s('Macro', { fg = magenta })
  s('Type', { fg = yellow })
  s('StorageClass', { fg = yellow })
  s('Structure', { fg = yellow })
  s('Typedef', { fg = yellow })
  s('Special', { fg = bcyan })
  s('SpecialChar', { fg = byellow })
  s('Delimiter', { fg = mid_fg })
  s('Tag', { fg = magenta })
  s('Debug', { fg = bred })
  s('Underlined', { fg = fg, underline = true })
  s('Ignore', { fg = muted })
  s('Error', { fg = bred, bold = true })
  s('Todo', { fg = byellow, bold = true })
  s('Bold', { bold = true })
  s('Italic', { italic = true })

  -- Diffs
  s('DiffAdd', { fg = green, bg = subtle })
  s('DiffChange', { fg = yellow, bg = subtle })
  s('DiffDelete', { fg = bred, bg = subtle })
  s('DiffText', { fg = byellow, bg = subtle, bold = true })
  link('Added', 'DiffAdd')
  link('Changed', 'DiffChange')
  link('Removed', 'DiffDelete')

  -- Editor UI
  s('Directory', { fg = blue, bold = true })
  s('MatchParen', { fg = byellow, bold = true, underline = true })
  s('NonText', { fg = muted })
  s('EndOfBuffer', { fg = darker_bg })
  s('LineNr', { fg = muted })
  s('CursorLineNr', { fg = acc, bold = true })
  s('CursorLine', { bg = cursorline })
  s('CursorColumn', { bg = cursorline })
  s('ColorColumn', { bg = colorcol })
  s('SignColumn', { bg = bg })
  s('Folded', { fg = muted, bg = dark_bg })
  s('FoldColumn', { fg = muted, bg = bg })
  s('Pmenu', { fg = fg, bg = dark_bg })
  s('PmenuSel', { fg = fg, bg = pmenu_sel })
  s('PmenuSbar', { bg = light_bg })
  s('PmenuThumb', { bg = muted })
  s('PmenuKind', { fg = cyan })
  s('PmenuKindSel', { fg = cyan, bg = pmenu_sel })
  s('PmenuExtra', { fg = dim_fg })
  s('PmenuExtraSel', { fg = dim_fg, bg = pmenu_sel })
  s('StatusLine', { fg = mid_fg, bg = dark_bg })
  s('StatusLineNC', { fg = muted, bg = darker_bg })
  s('TabLine', { fg = muted, bg = dark_bg })
  s('TabLineFill', { bg = darker_bg })
  s('TabLineSel', { fg = bg, bg = acc, bold = true })
  s('WinSeparator', { fg = separator, bg = bg })
  link('VertSplit', 'WinSeparator')
  s('Visual', { fg = fg, bg = sel })
  s('VisualNOS', { bg = sel })
  s('Search', { fg = bg, bg = yellow })
  s('IncSearch', { fg = bg, bg = orange })
  s('Substitute', { fg = bg, bg = red })
  s('QuickFixLine', { fg = fg, bg = sel })
  s('Title', { fg = acc, bold = true })
  s('WarningMsg', { fg = byellow })
  s('ErrorMsg', { fg = bred, bold = true })
  s('MoreMsg', { fg = green })
  s('ModeMsg', { fg = mid_fg })
  s('Question', { fg = cyan })
  s('SpecialKey', { fg = muted })
  s('Whitespace', { fg = darker_bg })
  s('Conceal', { fg = muted })
  s('SpellBad', { sp = bred, undercurl = true })
  s('SpellCap', { sp = bblue, undercurl = true })
  s('SpellLocal', { sp = bcyan, undercurl = true })
  s('SpellRare', { sp = bmagenta, undercurl = true })

  -- Treesitter
  s('@comment', { fg = dim_fg, italic = true })
  s('@constant', { fg = orange })
  s('@constant.builtin', { fg = orange })
  s('@string', { fg = green })
  s('@string.escape', { fg = bgreen })
  s('@number', { fg = orange })
  s('@boolean', { fg = orange })
  s('@function', { fg = blue })
  s('@function.call', { fg = blue })
  s('@method', { fg = blue })
  s('@keyword', { fg = magenta })
  s('@keyword.function', { fg = magenta })
  s('@keyword.operator', { fg = magenta })
  s('@keyword.return', { fg = magenta })
  s('@conditional', { fg = magenta })
  s('@repeat', { fg = magenta })
  s('@operator', { fg = magenta })
  s('@type', { fg = yellow })
  s('@type.builtin', { fg = yellow })
  s('@class', { fg = yellow })
  s('@variable', { fg = fg })
  s('@variable.builtin', { fg = bblue })
  s('@parameter', { fg = fg })
  s('@property', { fg = cyan })
  s('@field', { fg = cyan })
  s('@tag', { fg = magenta })
  s('@tag.delimiter', { fg = dim_fg })
  s('@attribute', { fg = cyan })
  s('@annotation', { fg = cyan })
  s('@punctuation.delimiter', { fg = mid_fg })
  s('@punctuation.bracket', { fg = mid_fg })
  s('@punctuation.special', { fg = bcyan })
  s('@markup.heading', { fg = acc, bold = true })
  s('@markup.link', { fg = cyan, underline = true })
  s('@markup.link.url', { fg = cyan, underline = true })
  s('@markup.strong', { bold = true })
  s('@markup.italic', { italic = true })
  s('@markup.raw', { fg = green })
  s('@diff.plus', { fg = green, bg = subtle })
  s('@diff.minus', { fg = bred, bg = subtle })
  s('@diff.delta', { fg = yellow, bg = subtle })
  s('@none', { fg = fg, bg = bg })

  -- LSP semantic tokens
  s('@lsp.type.class', { fg = yellow })
  s('@lsp.type.function', { fg = blue })
  s('@lsp.type.interface', { fg = yellow })
  s('@lsp.type.method', { fg = blue })
  s('@lsp.type.namespace', { fg = cyan })
  s('@lsp.type.parameter', { fg = fg })
  s('@lsp.type.property', { fg = cyan })
  s('@lsp.type.string', { fg = green })
  s('@lsp.type.variable', { fg = fg })
  s('@lsp.mod.deprecated', { strikethrough = true })
  s('@lsp.type.comment', { fg = dim_fg, italic = true })

  -- telescope.nvim
  s('TelescopeNormal', { fg = fg, bg = dark_bg })
  s('TelescopeBorder', { fg = muted, bg = dark_bg })
  s('TelescopePromptNormal', { fg = fg, bg = dark_bg })
  s('TelescopePromptBorder', { fg = acc, bg = dark_bg })
  s('TelescopePromptPrefix', { fg = acc })
  s('TelescopePromptTitle', { fg = bg, bg = acc })
  s('TelescopeResultsTitle', { fg = bg, bg = acc })
  s('TelescopePreviewTitle', { fg = bg, bg = acc })
  s('TelescopeSelection', { fg = fg, bg = sel })
  s('TelescopeSelectionCaret', { fg = acc, bg = sel })
  s('TelescopeMatching', { fg = byellow, bold = true })

  -- which-key.nvim
  s('WhichKey', { fg = acc })
  s('WhichKeyGroup', { fg = cyan })
  s('WhichKeyDesc', { fg = fg })
  s('WhichKeySeparator', { fg = muted })
  s('WhichKeyFloat', { bg = dark_bg })
  s('WhichKeyValue', { fg = dim_fg })

  -- gitsigns.nvim
  s('GitSignsAdd', { fg = green, bg = bg })
  s('GitSignsChange', { fg = yellow, bg = bg })
  s('GitSignsDelete', { fg = red, bg = bg })
  s('GitSignsAddNr', { fg = green })
  s('GitSignsChangeNr', { fg = yellow })
  s('GitSignsDeleteNr', { fg = red })

  -- nvim-cmp
  s('CmpItemAbbr', { fg = fg })
  s('CmpItemAbbrDeprecated', { fg = muted, strikethrough = true })
  s('CmpItemAbbrMatch', { fg = acc, bold = true })
  s('CmpItemAbbrMatchFuzzy', { fg = acc })
  s('CmpItemKind', { fg = cyan })
  s('CmpItemMenu', { fg = dim_fg })

  -- lazy.nvim
  s('LazyH1', { fg = bg, bg = acc, bold = true })
  s('LazyH2', { fg = acc, bold = true })
  s('LazyButton', { fg = fg, bg = dark_bg })
  s('LazyButtonActive', { fg = bg, bg = acc, bold = true })
  s('LazyComment', { fg = dim_fg })
  s('LazyProgressDone', { fg = acc, bold = true })
  s('LazyProgressTodo', { fg = muted })
  s('LazySpecial', { fg = cyan })
  s('LazyUrl', { fg = blue, underline = true })
  s('LazyDimmed', { fg = dim_fg })

  -- oil.nvim / trouble.nvim / indent guides
  s('OilDir', { fg = blue, bold = true })
  s('OilSocket', { fg = magenta })
  s('OilFile', { fg = fg })
  s('TroubleNormal', { fg = fg, bg = bg })
  s('TroubleText', { fg = mid_fg })
  s('TroubleCount', { fg = bg, bg = acc })
  s('IblIndent', { fg = separator_soft, nocombine = true })
  s('IblWhitespace', { fg = blend(bg, muted, 0.12), nocombine = true })
  s('IblScope', { fg = blend(bg, acc, 0.30), nocombine = true })
  s('IndentBlanklineChar', { fg = separator_soft })
  s('IndentBlanklineContextChar', { fg = blend(bg, acc, 0.45) })

  -- nvim-tree (sidebar explorer)
  local tree_bg = dark_bg
  s('NvimTreeNormal', { fg = fg, bg = tree_bg })
  s('NvimTreeNormalNC', { fg = mid_fg, bg = tree_bg })
  -- Blend the explorer/editor divider into the editor background.
  s('NvimTreeVertSplit', { fg = bg, bg = bg })
  s('NvimTreeWinSeparator', { fg = bg, bg = bg })
  s('NvimTreeEndOfBuffer', { fg = tree_bg, bg = tree_bg })
  s('NvimTreeSignColumn', { fg = tree_bg, bg = tree_bg })
  -- No cursor highlight in the tree; rows stay uniform.
  s('NvimTreeCursorLine', { fg = fg, bg = tree_bg })
  s('NvimTreeCursorColumn', { fg = fg, bg = tree_bg })
  s('NvimTreeCursorLineNr', { fg = mid_fg, bg = tree_bg })
  s('NvimTreeLineNr', { fg = blend(tree_bg, muted, 0.4), bg = tree_bg })

  s('NvimTreeRootFolder', { fg = acc, bg = tree_bg, bold = true })
  s('NvimTreeFolderName', { fg = blue, bg = tree_bg, bold = true })
  s('NvimTreeFolderIcon', { fg = blue, bg = tree_bg })
  s('NvimTreeOpenedFolderName', { fg = bblue, bg = tree_bg, bold = true })
  s('NvimTreeOpenedFolderIcon', { fg = bblue, bg = tree_bg })
  s('NvimTreeEmptyFolderName', { fg = dim_fg, bg = tree_bg })
  s('NvimTreeSpecialFolderName', { fg = byellow, bg = tree_bg })
  s('NvimTreeFolderArrowClosed', { fg = blend(tree_bg, muted, 0.55), bg = tree_bg })
  s('NvimTreeFolderArrowOpen', { fg = acc, bg = tree_bg })

  s('NvimTreeFileName', { fg = fg, bg = tree_bg })
  s('NvimTreeFileIcon', { fg = mid_fg, bg = tree_bg })
  s('NvimTreeOpenedFile', { fg = acc, bg = tree_bg })
  s('NvimTreeExecFile', { fg = green, bg = tree_bg, bold = true })
  s('NvimTreeImageFile', { fg = magenta, bg = tree_bg })
  s('NvimTreeSpecialFile', { fg = byellow, bg = tree_bg })
  s('NvimTreeSymlink', { fg = cyan, bg = tree_bg, italic = true })
  s('NvimTreeSymlinkIcon', { fg = cyan, bg = tree_bg })
  s('NvimTreeSymlinkFolderName', { fg = cyan, bg = tree_bg })
  s('NvimTreeModifiedFile', { fg = orange, bg = tree_bg, bold = true })
  s('NvimTreeModifiedIcon', { fg = orange, bg = tree_bg })
  s('NvimTreeBookmark', { fg = bmagenta, bg = tree_bg, bold = true })
  s('NvimTreeBookmarkIcon', { fg = bmagenta, bg = tree_bg })
  s('NvimTreeHiddenDisplay', { fg = dim_fg, bg = tree_bg, italic = true })
  s('NvimTreeIndentMarker', { fg = tree_separator, bg = tree_bg })

  -- Git states (icon, file and folder variants share the state color)
  s('NvimTreeGitDirty', { fg = yellow, bg = tree_bg })
  s('NvimTreeGitNew', { fg = green, bg = tree_bg })
  s('NvimTreeGitDeleted', { fg = bred, bg = tree_bg })
  s('NvimTreeGitStaged', { fg = cyan, bg = tree_bg })
  s('NvimTreeGitRenamed', { fg = bcyan, bg = tree_bg })
  s('NvimTreeGitIgnored', { fg = dim_fg, bg = tree_bg })
  s('NvimTreeGitMerge', { fg = bmagenta, bg = tree_bg })
  for _, kind in ipairs({ 'Dirty', 'New', 'Deleted', 'Staged', 'Renamed', 'Ignored', 'Merge' }) do
    link('NvimTreeGit' .. kind .. 'Icon', 'NvimTreeGit' .. kind)
    link('NvimTreeFile' .. kind, 'NvimTreeGit' .. kind)
    link('NvimTreeFolder' .. kind, 'NvimTreeGit' .. kind)
    link('NvimTreeGitFile' .. kind .. 'HL', 'NvimTreeGit' .. kind)
    link('NvimTreeGitFolder' .. kind .. 'HL', 'NvimTreeGit' .. kind)
  end
  s('NvimTreeCopiedHL', { fg = green, bg = tree_bg, bold = true })
  s('NvimTreeCutHL', { fg = red, bg = tree_bg, bold = true })

  -- Diagnostics shown beside files/folders
  s('NvimTreeDiagnosticErrorIcon', { fg = bred, bg = tree_bg })
  s('NvimTreeDiagnosticWarnIcon', { fg = byellow, bg = tree_bg })
  s('NvimTreeDiagnosticInfoIcon', { fg = bblue, bg = tree_bg })
  s('NvimTreeDiagnosticHintIcon', { fg = bcyan, bg = tree_bg })
  for _, level in ipairs({ 'Error', 'Warn', 'Info', 'Hint' }) do
    link('NvimTreeDiagnostic' .. level .. 'FileHL', 'NvimTreeDiagnostic' .. level .. 'Icon')
    link('NvimTreeDiagnostic' .. level .. 'FolderHL', 'NvimTreeDiagnostic' .. level .. 'Icon')
  end

  -- Live filter and floating picker
  s('NvimTreeFilter', { fg = byellow, bg = tree_bg })
  s('NvimTreeLiveFilterPrefix', { fg = acc, bg = tree_bg, bold = true })
  s('NvimTreeLiveFilterValue', { fg = byellow, bg = tree_bg })
  s('NvimTreeWindowPicker', { fg = bg, bg = acc, bold = true })
  s('NvimTreeNormalFloat', { fg = fg, bg = dark_bg })
  s('NvimTreeNormalFloatBorder', { fg = float_border, bg = dark_bg })
  s('NvimTreePopup', { fg = fg, bg = dark_bg })

  -- bufferline.nvim: tabline is a distinct surface, not the editor background.
  s('BufferLineFill', { bg = tabline_bg })
  -- Tabline block sitting above the sidebar (bufferline offset)
  s('BufferLineExplorerOffset', { fg = acc, bg = dark_bg, bold = true })
  s('BufferLineOffsetSeparator', { fg = tabline_border, bg = tabline_bg })
  s('BufferLineBackground', { fg = mid_fg, bg = tab_inactive })
  s('BufferLineBufferVisible', { fg = fg, bg = blend(tabline_bg, muted, 0.16) })
  s('BufferLineBufferSelected', { fg = bright_fg, bg = tab_active, bold = true })
  s('BufferLineIndicatorSelected', { fg = acc, bg = tab_active })
  s('BufferLineSeparator', { fg = tab_separator, bg = tab_inactive })
  s('BufferLineSeparatorSelected', { fg = tabline_border, bg = tab_active })
  s('BufferLineCloseButton', { fg = muted, bg = tab_inactive })
  s('BufferLineCloseButtonSelected', { fg = bright_fg, bg = tab_active })
  s('BufferLineModified', { fg = yellow, bg = tab_inactive })
  s('BufferLineModifiedSelected', { fg = byellow, bg = tab_active })
  s('BufferLineTab', { fg = muted, bg = tab_inactive })
  s('BufferLineTabSelected', { fg = bg, bg = acc, bold = true })
  s('BufferLineNumbers', { fg = dim_fg, bg = tab_inactive })
  s('BufferLineNumbersSelected', { fg = mid_fg, bg = tab_active })
  s('BufferLineError', { fg = bred, bg = tab_inactive })
  s('BufferLineErrorSelected', { fg = bred, bg = tab_active })
  s('BufferLineWarning', { fg = byellow, bg = tab_inactive })
  s('BufferLineWarningSelected', { fg = byellow, bg = tab_active })
  s('BufferLinePick', { fg = bred, bg = tab_inactive, bold = true })
  s('BufferLinePickSelected', { fg = bred, bg = tab_active, bold = true })

  -- nvim-notify
  s('NotifyBackground', { bg = dark_bg })
  s('NotifyBorder', { fg = muted, bg = dark_bg })
  s('NotifyERROR', { fg = bred })
  s('NotifyWARN', { fg = byellow })
  s('NotifyINFO', { fg = bblue })
  s('NotifyDEBUG', { fg = muted })
  s('NotifyTRACE', { fg = bmagenta })
  s('NotifyERRORTitle', { fg = bred, bold = true })
  s('NotifyWARNTitle', { fg = byellow, bold = true })
  s('NotifyINFOTitle', { fg = bblue, bold = true })
  s('NotifyDEBUGTitle', { fg = muted, bold = true })
  s('NotifyTRACETitle', { fg = bmagenta, bold = true })
  s('NotifyIcon', { fg = acc })
  s('NotifyTitle', { fg = fg, bold = true })
  s('NotifyBody', { fg = mid_fg })

  -- nvim-scrollbar v2
  s('ScrollbarBase', { bg = dark_bg })
  s('ScrollbarTrack', { bg = blend(dark_bg, muted, 0.12) })
  s('ScrollbarThumb', { fg = muted, bg = blend(bg, muted, 0.30) })
  s('ScrollbarCursorThumb', { fg = acc, bg = dark_bg })
  s('ScrollbarSearchThumb', { fg = byellow, bg = dark_bg })
  s('ScrollbarErrorThumb', { fg = bred, bg = dark_bg })
  s('ScrollbarWarnThumb', { fg = byellow, bg = dark_bg })
  s('ScrollbarInfoThumb', { fg = bblue, bg = dark_bg })
  s('ScrollbarHintThumb', { fg = bcyan, bg = dark_bg })
  s('ScrollbarCursor', { fg = acc })
  s('ScrollbarSearch', { fg = byellow })
  s('ScrollbarError', { fg = bred })
  s('ScrollbarWarn', { fg = byellow })
  s('ScrollbarInfo', { fg = bblue })
  s('ScrollbarHint', { fg = bcyan })

  -- alpha-nvim (dashboard)
  s('AlphaHeader', { fg = acc, bold = true })
  s('AlphaButtons', { fg = cyan })
  s('AlphaShortcut', { fg = byellow, bold = true })
  s('AlphaFooter', { fg = dim_fg, italic = true })

  -- flash.nvim
  s('FlashBackdrop', { fg = dim_fg })
  s('FlashMatch', { fg = byellow, bg = dark_bg })
  s('FlashCurrent', { fg = bg, bg = acc, bold = true })
  s('FlashLabel', { fg = bg, bg = bmagenta, bold = true })

  -- aerial.nvim
  s('AerialLine', { bg = cursorline })
  s('AerialGuide', { fg = separator_soft })
  s('AerialFileIcon', { fg = blue })
  s('AerialDirectoryIcon', { fg = yellow })

  -- Diagnostics
  s('DiagnosticError', { fg = bred })
  s('DiagnosticWarn', { fg = byellow })
  s('DiagnosticInfo', { fg = bblue })
  s('DiagnosticHint', { fg = bcyan })
  s('DiagnosticOk', { fg = green })
  s('DiagnosticFloatingError', { fg = bred })
  s('DiagnosticFloatingWarn', { fg = byellow })
  s('DiagnosticFloatingInfo', { fg = bblue })
  s('DiagnosticFloatingHint', { fg = bcyan })
  s('DiagnosticSignError', { fg = bred })
  s('DiagnosticSignWarn', { fg = byellow })
  s('DiagnosticSignInfo', { fg = bblue })
  s('DiagnosticSignHint', { fg = bcyan })
  s('DiagnosticUnderlineError', { sp = bred, undercurl = true })
  s('DiagnosticUnderlineWarn', { sp = byellow, undercurl = true })
  s('DiagnosticUnderlineInfo', { sp = bblue, undercurl = true })
  s('DiagnosticUnderlineHint', { sp = bcyan, undercurl = true })

  -- mini.map (minimap)
  s('MiniMapNormal', { fg = blend(bg, mid_fg, 0.55), bg = dark_bg })
  s('MiniMapSymbolLine', { fg = acc, bg = dark_bg })
  s('MiniMapSymbolView', { fg = blend(dark_bg, acc, 0.40), bg = dark_bg })
  s('MiniMapSymbolCount', { fg = byellow, bg = dark_bg })

  -- Cursor
  s('Cursor', { fg = p.cursor_text, bg = p.cursor })
  vim.opt.guicursor:append('a:Cursor/lCursor')
end

local function set_terminal(p)
  local colors = {
    p.darker_background, p.red, p.green, p.yellow,
    p.blue, p.magenta, p.cyan, p.light_foreground,
    p.muted, p.bright_red, p.bright_green, p.bright_yellow,
    p.bright_blue, p.bright_magenta, p.bright_cyan, p.bright_foreground,
  }
  for i, value in ipairs(colors) do
    vim.g['terminal_color_' .. (i - 1)] = value
  end
end

-- Public API -----------------------------------------------------------------
function M.list()
  return vim.deepcopy(THEMES)
end

-- Return the raw (normalised) palette for a theme, defaulting to the active one.
function M.palette(name)
  return load_palette(name or M.current or 'jellybeans')
end

function M.apply(name)
  if not KNOWN[name] then
    vim.notify('[kuro-themes] Unknown theme: ' .. tostring(name), vim.log.levels.WARN)
    return false
  end

  local p = load_palette(name)

  vim.cmd('highlight clear')
  pcall(vim.cmd, 'syntax reset')

  vim.g.colors_name = name
  vim.opt.background = p.mode == 'light' and 'light' or 'dark'

  define(p)
  set_terminal(p)

  M.current = name
  return true
end

function M.use(name)
  if not M.apply(name) then
    return false
  end

  vim.fn.mkdir(vim.fn.stdpath('state'), 'p')
  local file = io.open(STATE_FILE, 'w')
  if file then
    file:write(name)
    file:close()
  end

  vim.api.nvim_exec_autocmds('ColorScheme', { modeline = false })
  return true
end

function M.setup(opts)
  opts = opts or {}

  local saved
  local file = io.open(STATE_FILE, 'r')
  if file then
    saved = vim.trim(file:read('*a') or '')
    file:close()
  end

  local default = opts.default or 'jellybeans'
  if not KNOWN[default] then
    default = 'jellybeans'
  end
  local initial = kuro_scheme() or ((saved and KNOWN[saved]) and saved) or default

  M.apply(initial)
  watch_kuro_theme()

  vim.api.nvim_create_user_command('KuroTheme', function(args)
    local requested = vim.trim(args.args or '')
    if requested == '' then
      vim.ui.select(THEMES, { prompt = 'Select Kuro theme' }, function(choice)
        if choice then
          M.use(choice)
        end
      end)
    else
      M.use(requested)
    end
  end, {
    nargs = '?',
    complete = function(arglead)
      local result = {}
      for _, theme in ipairs(THEMES) do
        if theme:find(arglead, 1, true) == 1 then
          result[#result + 1] = theme
        end
      end
      return result
    end,
    desc = 'Switch between the 11 Kuro colorschemes',
  })

  return M
end

return M
