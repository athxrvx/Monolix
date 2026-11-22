-- Extra everyday tooling: navigation, editing, git, terminal and sessions.
return {
  -- Faster fuzzy matching for Telescope
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make',
    cond = function()
      return vim.fn.executable('make') == 1
    end,
  },

  -- Motion: jump anywhere with `s`, treesitter-aware with `S`
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    keys = {
      { 's', function() require('flash').jump() end, mode = { 'n', 'x' }, desc = 'Flash jump' },
      { 'S', function() require('flash').treesitter() end, mode = { 'n', 'x' }, desc = 'Flash treesitter' },
      { 'r', function() require('flash').remote() end, mode = 'o', desc = 'Remote flash' },
      { 'R', function() require('flash').treesitter_search() end, mode = { 'o', 'x' }, desc = 'Flash treesitter search' },
      { '<C-s>', function() require('flash').toggle() end, mode = 'c', desc = 'Toggle flash search' },
    },
    opts = {
      labels = 'asdfghjklqwertyuiopzxcvbnm',
      search = { multi_window = true, wrap = true },
      jump = { autojump = true },
    },
  },

  -- Code outline sidebar
  {
    'stevearc/aerial.nvim',
    cmd = { 'AerialToggle', 'AerialOpen', 'AerialNavOpen' },
    keys = {
      { '<leader>ao', '<cmd>AerialToggle<cr>', desc = 'Toggle code outline' },
    },
    opts = {
      layout = { position = 'right', width = 35 },
      attach_mode = 'global',
      backends = { 'lsp', 'treesitter' },
    },
  },

  -- Vim-style surroundings: ys, cs, ds
  {
    'kylechui/nvim-surround',
    event = 'VeryLazy',
    opts = {},
  },

  -- Auto-close / auto-rename HTML-style tags
  {
    'windwp/nvim-ts-autotag',
    event = 'InsertEnter',
    ft = { 'html', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue', 'svelte', 'jsx', 'tsx' },
    opts = {},
  },

  -- Rich git diffs and file history
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    keys = {
      { '<leader>gv', '<cmd>DiffviewOpen<cr>', desc = 'Open diff view' },
      { '<leader>gh', '<cmd>DiffviewFileHistory<cr>', desc = 'File history' },
    },
    opts = {},
  },

  -- Toggleable terminal
  {
    'akinsho/toggleterm.nvim',
    cmd = 'ToggleTerm',
    keys = {
      { '<leader>tt', '<cmd>ToggleTerm<cr>', desc = 'Toggle terminal' },
      { '<leader>tf', '<cmd>ToggleTerm direction=float<cr>', desc = 'Floating terminal' },
    },
    opts = {
      size = 20,
      open_mapping = false,
      direction = 'horizontal',
      shade_terminals = true,
      float_opts = { border = 'rounded' },
    },
  },

  -- Yank history with Telescope picker
  {
    'gbprod/yanky.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    keys = {
      { 'y', '<Plug>(YankyYank)', mode = { 'n', 'x' } },
      { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' } },
      { 'P', '<Plug>(YankyPutBefore)', mode = { 'n', 'x' } },
      { ']y', '<Plug>(YankyCycleForward)', desc = 'Next yank' },
      { '[y', '<Plug>(YankyCycleBackward)', desc = 'Previous yank' },
      { '<leader>yy', function() require('yanky.picker').history() end, desc = 'Yank history' },
    },
    opts = {
      ring = { history_length = 20, storage = 'shada' },
      picker = { history = { type = 'telescope' } },
    },
  },

  -- Session management
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    keys = {
      { '<leader>qs', function() require('persistence').save() end, desc = 'Save session' },
      { '<leader>ql', function() require('persistence').load({ last = true }) end, desc = 'Load last session' },
      { '<leader>qd', function() require('persistence').stop() end, desc = 'Stop session' },
    },
    opts = {},
  },

  -- Better Lua development (workspace libraries for lua_ls)
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },

  -- Formatter engine with LSP fallback
  {
    'stevearc/conform.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    cmd = 'ConformInfo',
    keys = {
      {
        '<leader>fm',
        function()
          require('conform').format({ async = true, lsp_fallback = true })
        end,
        mode = { 'n', 'v' },
        desc = 'Format with conform',
      },
      {
        '<leader>uF',
        function()
          vim.b.kuro_autoformat = not vim.b.kuro_autoformat
          vim.notify('Autoformat ' .. (vim.b.kuro_autoformat and 'enabled' or 'disabled') .. ' for this buffer')
        end,
        desc = 'Toggle autoformat for buffer',
      },
    },
    opts = {
      format_on_save = function(bufnr)
        if not vim.b[bufnr].kuro_autoformat then
          return
        end
        return { timeout_ms = 1000, lsp_fallback = true }
      end,
      formatters_by_ft = {
        -- Web (prettierd installed by Mason; prettier used if available locally)
        javascript = { 'prettierd', 'prettier' },
        javascriptreact = { 'prettierd', 'prettier' },
        typescript = { 'prettierd', 'prettier' },
        typescriptreact = { 'prettierd', 'prettier' },
        vue = { 'prettierd', 'prettier' },
        css = { 'prettierd', 'prettier' },
        scss = { 'prettierd', 'prettier' },
        html = { 'prettierd', 'prettier' },
        json = { 'prettierd', 'prettier' },
        yaml = { 'prettierd', 'prettier' },
        markdown = { 'prettierd', 'prettier' },
        -- Rust (rustfmt comes from the Rust toolchain)
        rust = { 'rustfmt' },
      },
    },
  },
}
