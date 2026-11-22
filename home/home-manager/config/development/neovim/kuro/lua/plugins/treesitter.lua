local parsers = {
  'bash', 'c', 'cpp', 'css', 'go', 'html', 'javascript', 'json', 'lua',
  'markdown', 'python', 'query', 'rust', 'tsx', 'typescript', 'vim', 'yaml',
}

return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPost', 'BufNewFile' },
  config = function()
    local opts = {
      ensure_installed = parsers,
      auto_install = true,
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      indent = { enable = true },
    }

    -- Support both the legacy (master) and current (main) treesitter APIs.
    local ok, configs = pcall(require, 'nvim-treesitter.configs')
    if ok then
      configs.setup(opts)
    else
      require('nvim-treesitter').setup(opts)
    end
  end,
}
