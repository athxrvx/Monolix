local stl = require("monovim_config").ui.statusline

if not stl.enabled then
  return {}
end

local theme_module = "monovim_base46.integrations.statusline." .. stl.theme
return require(theme_module)
