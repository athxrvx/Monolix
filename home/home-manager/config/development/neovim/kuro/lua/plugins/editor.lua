return {
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = { delay = 300 },
  },
  {
    'numToStr/Comment.nvim',
    keys = { 'gcc', 'gc', 'gbc', 'gb' },
    opts = {},
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = { check_ts = true },
  },
  {
    'stevearc/oil.nvim',
    cmd = 'Oil',
    keys = {
      { '<leader>o', '<cmd>Oil<cr>', desc = 'Open Oil buffer explorer' },
    },
    opts = {
      default_file_explorer = false,
      view_options = { show_hidden = true },
      float = { padding = 2 },
    },
  },
  {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (Trouble)' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer diagnostics' },
    },
    opts = {},
  },
}
