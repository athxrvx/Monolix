local api = vim.api
local config = require "monovim_config"
local new_cmd = api.nvim_create_user_command

if config.ui.statusline.enabled then
  vim.o.statusline = "%!v:lua.require('monovim.stl." .. config.ui.statusline.theme .. "')()"
  require("monovim.stl.utils").autocmds()
end

if config.ui.tabufline.enabled then
  require "monovim.tabufline.lazyload"
end

-- Command to toggle MonoDash
new_cmd("Monodash", function()
  if vim.g.monodash_displayed then
    require("monovim.tabufline").close_buffer(vim.g.monodash_buf)
  else
    require("monovim.monodash").open()
  end
end, {})

new_cmd("MonoCheatsheet", function()
  if vim.g.monosheet_displayed then
    vim.cmd "bw"
  else
    require("monovim.cheatsheet." .. config.cheatsheet.theme)()
  end
end, {})

new_cmd("MasonInstallAll", function()
  require("monovim.mason").install_all()
end, {})

vim.schedule(function()
  require "monovim.au"
end)
