local colors = require("monovim_base46").get_theme_tb "base_30"

local opts = require("monovim_config").monovim_base46

if opts.transparency then
  return {}
end

return {
  SagaBorder = {
    bg = colors.darker_black,
  },
  SagaNormal = {
    bg = colors.darker_black,
  },
}
