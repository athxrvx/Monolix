local get_theme_tb = require("monovim_base46").get_theme_tb
local colors = get_theme_tb "base_30"
local theme_type = get_theme_tb "type"
local tune_color = require("monovim_base46.colors").change_hex_lightness

return {
  MonoimTreeEmptyFolderName = { fg = colors.folder_bg },
  MonoimTreeEndOfBuffer = { fg = colors.darker_black },
  MonoimTreeFolderIcon = { fg = colors.folder_bg },
  MonoimTreeFolderName = { fg = colors.folder_bg },
  MonoimTreeFolderArrowOpen = { fg = colors.folder_bg },
  MonoimTreeFolderArrowClosed = { fg = colors.grey_fg },
  MonoimTreeGitDirty = { fg = colors.red },
  MonoimTreeIndentMarker = { fg = (theme_type == "dark" and tune_color(colors.line, -2) or colors.one_bg2) },
  MonoimTreeNormal = { bg = colors.darker_black },
  MonoimTreeNormalNC = { bg = colors.darker_black },
  MonoimTreeOpenedFolderName = { fg = colors.folder_bg },
  MonoimTreeGitIgnored = { fg = colors.light_grey },
  MonoimTreeDiagnosticErrorFileHL = { link = "DiagnosticError" },
  MonoimTreeDiagnosticErrorFolderHL = { link = "DiagnosticError" },
  MonoimTreeDiagnosticInfoFileHL =  { link = "DiagnosticNormal" },
  MonoimTreeDiagnosticInfoFolderHL =  { link = "DiagnosticNormal" },
  MonoimTreeDiagnosticWarnFileHL = { link = "DiagnosticWarn" },
  MonoimTreeDiagnosticWarnFolderHL = { link = "DiagnosticWarn" },
  MonoimTreeDiagnosticHintFileHL = { link = "DiagnosticHint" },
  MonoimTreeDiagnosticHintFolderHL = { link = "DiagnosticHint" },

  MonoimTreeWinSeparator = {
    fg = colors.darker_black,
    bg = colors.darker_black,
  },

  MonoimTreeWindowPicker = {
    fg = colors.red,
    bg = colors.black2,
  },

  MonoimTreeCursorLine = {
    bg = colors.black,
  },

  MonoimTreeGitNew = {
    fg = colors.yellow,
  },

  MonoimTreeGitDeleted = {
    fg = colors.red,
  },

  MonoimTreeSpecialFile = {
    fg = colors.yellow,
    bold = true,
  },

  MonoimTreeRootFolder = {
    fg = colors.red,
    bold = true,
  },
}
