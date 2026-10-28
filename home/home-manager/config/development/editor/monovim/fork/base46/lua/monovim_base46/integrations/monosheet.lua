local colors = require("monovim_base46").get_theme_tb "base_30"

local M = {
  MonoChHeading = {
    fg = colors.black,
    bg = colors.blue,
    bold = true,
  },

  MonoChSection = {
    bg = colors.black2,
  },

  MonoChAsciiHeader = {
    fg = colors.blue,
    bg = colors.black2,
  },
}

local cheatsheet_theme = require("monovim_config").cheatsheet.theme

if cheatsheet_theme == "grid" then
  M.MonoChAsciiHeader = {
    fg = colors.blue,
  }

  local bgcols =
    { "blue", "red", "green", "yellow", "orange", "baby_pink", "purple", "white", "cyan", "vibrant_green", "teal" }

  for _, value in ipairs(bgcols) do
    M["MonoChHead" .. value] = {
      fg = colors.black,
      bg = colors[value],
    }
  end
end

return M
