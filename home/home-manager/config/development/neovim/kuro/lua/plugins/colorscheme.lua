-- Local lazy.nvim plugin that provides the 11 Kuro colorschemes.
-- Palettes are read from ~/.config/kuro/themes/*.toml at runtime.
return {
  {
    dir = vim.fn.stdpath('config') .. '/kuro-themes',
    name = 'kuro-themes',
    lazy = false,
    priority = 1000,
    config = function()
      require('kuro-themes').setup({ default = 'jellybeans' })
    end,
  },
}
