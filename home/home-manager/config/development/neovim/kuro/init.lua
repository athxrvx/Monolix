-- ============================================================================
-- init.lua -- Neovim entry point
-- ============================================================================

-- Bootstrap lazy.nvim (plugin manager) ---------------------------------------
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim.\n', 'ErrorMsg' },
      { 'Make sure git is installed and you have an internet connection.', 'None' },
    }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

-- Core settings (loaded before plugins / keymaps) ----------------------------
require('core.options')
require('core.keymaps')
require('core.autocmds')

-- Plugins (specs live in lua/plugins/*.lua) ----------------------------------
require('lazy').setup({
  spec = {
    { import = 'plugins' },
  },
  install = { colorscheme = { 'jellybeans' } },
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip',
        'netrwPlugin',
        'rplugin',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
})
