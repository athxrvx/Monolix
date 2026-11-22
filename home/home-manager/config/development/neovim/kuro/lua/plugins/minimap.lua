local excluded = {
  alpha = true,
  dashboard = true,
  oil = true,
  NvimTree = true,
  aerial = true,
  notify = true,
  toggleterm = true,
  lazy = true,
  help = true,
  qf = true,
  starter = true,
  Trouble = true,
  snacks_dashboard = true,
}

return {
  'nvim-mini/mini.map',
  version = false,
  event = 'BufReadPost',

  keys = {
    { '<leader>mt', function() require('mini.map').toggle() end, desc = 'Toggle minimap' },
    { '<leader>mo', function() require('mini.map').open() end, desc = 'Open minimap' },
    { '<leader>mc', function() require('mini.map').close() end, desc = 'Close minimap' },
    { '<leader>mf', function() require('mini.map').toggle_focus() end, desc = 'Focus minimap' },
    { '<leader>ms', function() require('mini.map').toggle_side() end, desc = 'Flip minimap side' },
  },

  config = function()
    local map = require('mini.map')

    -- Integrations
    local integrations = {
      map.gen_integration.builtin_search(),
      map.gen_integration.diagnostic({
        error = 'DiagnosticFloatingError',
        warn  = 'DiagnosticFloatingWarn',
        info  = 'DiagnosticFloatingInfo',
        hint  = 'DiagnosticFloatingHint',
      }),
    }

    -- Git integration
    local ok, git = pcall(map.gen_integration.gitsigns)
    if ok and git then
      table.insert(integrations, git)
    end

    -- Setup
    map.setup({
      integrations = integrations,

      symbols = {
        encode = map.gen_encode_symbols.block('3x2'),
        scroll_line = '█',
        scroll_view = '┃',
      },

      window = {
        side = 'left',
        width = 12,
        winblend = 20,
        focusable = false,
        show_integration_count = true,
        zindex = 10,
      },
    })

    -- Jellybeans-inspired highlights
    local function set_highlights()
      local highlights = {
        MiniMapNormal = {
          fg = '#8197bf',
          bg = '#151515',
        },

        MiniMapSymbolCount = {
          fg = '#888888',
          bg = '#151515',
        },

        MiniMapSymbolLine = {
          fg = '#8197bf',
          bg = '#151515',
        },

        MiniMapSymbolView = {
          fg = '#99ad6a',
          bg = '#303030',
        },

        DiagnosticFloatingError = {
          fg = '#cf6a4c',
        },

        DiagnosticFloatingWarn = {
          fg = '#fad07a',
        },

        DiagnosticFloatingInfo = {
          fg = '#8197bf',
        },

        DiagnosticFloatingHint = {
          fg = '#99ad6a',
        },
      }

      for group, opts in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, opts)
      end
    end

    set_highlights()

    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('KuroMinimapHighlights', {
        clear = true,
      }),
      callback = set_highlights,
    })

    -- Buffer validation
    local function valid_buffer()
      if vim.g.minimap_disable then
        return false
      end

      if not vim.api.nvim_buf_is_valid(0) then
        return false
      end

      if vim.bo.buftype ~= '' then
        return false
      end

      if excluded[vim.bo.filetype] then
        return false
      end

      if vim.api.nvim_buf_get_name(0) == '' then
        return false
      end

      return true
    end

    -- Automatic minimap
    local function maybe_open()
      if not valid_buffer() then
        return
      end

      local ok, is_open = pcall(map.is_open)

      if ok and not is_open then
        pcall(map.open)
      end
    end

    -- Initial opening
    vim.defer_fn(maybe_open, 200)

    -- Open on buffer changes
    local group = vim.api.nvim_create_augroup('KuroMinimap', {
      clear = true,
    })

    vim.api.nvim_create_autocmd('BufEnter', {
      group = group,
      callback = function()
        vim.defer_fn(maybe_open, 100)
      end,
    })

    -- Close minimap when entering excluded buffers
    vim.api.nvim_create_autocmd('BufEnter', {
      group = group,
      callback = function()
        if not valid_buffer() then
          pcall(map.close)
        end
      end,
    })
  end,
}

