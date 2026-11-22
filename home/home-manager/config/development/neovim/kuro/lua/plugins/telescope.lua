return {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-fzf-native.nvim',
    'nvim-telescope/telescope-ui-select.nvim',
  },
  cmd = 'Telescope',
  keys = {
    { '<leader>ff', function() require('telescope.builtin').find_files({ hidden = true }) end, desc = 'Find files' },
    { '<leader>fg', function() require('telescope.builtin').live_grep() end, desc = 'Live grep' },
    { '<leader>fb', function() require('telescope.builtin').buffers() end, desc = 'Find buffers' },
    { '<leader>fh', function() require('telescope.builtin').help_tags() end, desc = 'Search help' },
    { '<leader>fr', function() require('telescope.builtin').oldfiles() end, desc = 'Recent files' },
    { '<leader>fd', function() require('telescope.builtin').diagnostics() end, desc = 'Search diagnostics' },
    { '<leader>gc', function() require('telescope.builtin').git_commits() end, desc = 'Git commits' },
  },
  config = function()
    require('telescope').setup({
      defaults = {
        layout_config = { horizontal = { preview_width = 0.55 } },
        mappings = { i = { ['<C-u>'] = false, ['<C-d>'] = false } },
        file_ignore_patterns = { 'node_modules', '.git/' },
      },
      pickers = {
        find_files = { hidden = true },
      },
      extensions = {
        ['ui-select'] = { require('telescope.themes').get_dropdown({}) },
      },
    })

    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')
    pcall(require('telescope').load_extension, 'yank_history')
  end,
}
