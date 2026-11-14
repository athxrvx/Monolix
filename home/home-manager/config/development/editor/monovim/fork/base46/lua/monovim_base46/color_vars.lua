local opts = require("monovim_config").monovim_base46
local str = ""

local present1, default_theme = pcall(require, "monovim_base46.themes." .. opts.theme)
local colors = (present1 and default_theme) or require("themes." .. opts.theme)

for name, hex in pairs(colors.base_30) do
  str = str .. name .. "='" .. hex
  str = str .. "',"
end

str = "return {" .. str .. "}"

return str
