-- Visual interface: statusline, tabline, indent guides, notifications,
-- scrollbar and a start screen.
return {
  {
    'nvim-tree/nvim-web-devicons',
    lazy = true,
  },

  -- Sidebar file explorer
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = { 'NvimTreeToggle', 'NvimTreeFindFile' },
    keys = {
      { '<leader>e', '<cmd>NvimTreeToggle<cr>', desc = 'Toggle sidebar explorer' },
      { '<leader>ef', '<cmd>NvimTreeFindFile<cr>', desc = 'Reveal current file' },
    },
    opts = {
      hijack_netrw = true,
      respect_buf_cwd = true,
      update_cwd = true,
      sync_root_with_cwd = true,
      view = {
        width = 60,
        side = 'right',
        number = false,
        relativenumber = false,
        signcolumn = 'no',
        preserve_window_proportions = true,
      },
      renderer = {
        symlink_destination = false,
        group_empty = true,
        highlight_git = true,
        highlight_opened_files = 'name',
        highlight_modified = 'all',
        root_folder_label = false,
        hidden_display = 'all',
        indent_markers = {
          enable = true,
          inline_arrows = false,
          icons = { corner = '└', edge = '│', item = '├', bottom = '─', none = ' ' },
        },
        icons = {
          show = { git = false, folder = true, file = true, folder_arrow = false, modified = true },
          webdev_colors = true,
          padding = { icon = '   ', folder_arrow = '  ' },
          glyphs = {
            default = '',
            symlink = '',
            modified = '●',
            folder = { arrow_closed = '▸', arrow_open = '▾', default = '', open = '', empty = '', empty_open = '', symlink = '' },
            --git = {
            --  unstaged = '~',
            --  staged = '+',
            --  unmerged = '≡',
            --  renamed = '➜',
            --  deleted = '✗',
            --  untracked = '?',
            -- ignored = '◌',
            -- },
          },
        },
      },
      diagnostics = {
        enable = true,
        icons = { hint = '', info = '', warning = '', error = '' },
      },
      update_focused_file = { enable = true, update_cwd = true },
      modified = { enable = true, show_on_dirs = true },
      git = { enable = true, ignore = false, timeout = 300 },
      filters = { dotfiles = false, git_ignored = false },
      live_filter = { prefix = ' Filter: ', always_show_folders = false },
      actions = {
        open_file = {
          quit_on_open = false,
          resize_window = true,
          window_picker = { enable = true },
        },
      },
    },
    config = function(_, opts)
      require('nvim-tree').setup(opts)
      -- nvim-tree has no left-padding option; its sign column shares the tree
      -- background, so reserve two columns for a seamless left gutter.
      require('nvim-tree.api').events.subscribe('TreeOpen', function()
        if vim.bo.filetype == 'NvimTree' then
          vim.wo.signcolumn = 'yes:2'
          vim.wo.cursorline = false
          vim.wo.cursorcolumn = false
        end
      end)
    end,
  },

  -- Statusline
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = function()
      local function lsp_clients()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          return ''
        end
        local names = {}
        for _, client in ipairs(clients) do
          names[#names + 1] = client.name
        end
        return ' ' .. table.concat(names, ', ')
      end

      -- Lualine re-evaluates a function theme on every ColorScheme event, so
      -- the modeline follows the active Kuro palette completely.
      local function brighten(hex, amount)
        local h = (hex or ''):gsub('#', '')
        if #h == 3 then
          h = h:gsub('(.)(.)(.)', '%1%1%2%2%3%3')
        end
        if #h ~= 6 then
          return hex
        end
        local function mix(pair)
          local value = tonumber(pair, 16) or 0
          return math.floor(value + (255 - value) * amount + 0.5)
        end
        return string.format('#%02x%02x%02x', mix(h:sub(1, 2)), mix(h:sub(3, 4)), mix(h:sub(5, 6)))
      end

      local function palette_theme()
        local p = require('kuro-themes').palette()
        local function hl(fg, bg, gui)
          return { fg = fg, bg = bg, gui = gui }
        end
        -- The bar sits a shade above the editor background, never exactly on it.
        local base = brighten(p.dark_background, 0.06)
        local mid = brighten(p.background, 0.10)
        local fore = p.foreground
        local function mode(accent)
          return {
            a = hl(base, accent, 'bold'),
            b = hl(fore, base),
            c = hl(fore, mid),
          }
        end
        return {
          normal = mode(p.accent),
          insert = mode(p.green),
          visual = mode(p.magenta),
          replace = mode(p.red),
          command = mode(p.yellow),
          terminal = mode(p.cyan),
          inactive = {
            a = hl(p.muted, base),
            b = hl(p.muted, base),
            c = hl(p.muted, mid),
          },
        }
      end

      return {
        options = {
          theme = palette_theme,
          globalstatus = true,
          component_separators = { left = '│', right = '│' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = { statusline = { 'alpha', 'notify' } },
        },
        sections = {
          lualine_a = {
            {
              'mode',
              fmt = function(str)
                return str:sub(1, 1) .. str:sub(2):lower()
              end,
            },
          },
          lualine_b = {
            { 'branch', icon = '' },
            'diff',
          },
          lualine_c = {
            {
              'filename',
              path = 1,
              file_status = true,
              symbols = { modified = '●', readonly = '🔒', unnamed = '[No Name]' },
            },
          },
          lualine_x = {
            {
              'diagnostics',
              sources = { 'nvim_diagnostic' },
              symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
            },
            'searchcount',
            lsp_clients,
            { 'filetype', icon_only = false },
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
        },
      }
    end,
  },

  -- tab line
  {
      "romgrk/barbar.nvim",
      dependencies = {
          "nvim-tree/nvim-web-devicons",
      },
      init = function()
          vim.g.barbar_auto_setup = false
      end,

      config = function()
          local colors = {
              bg      = "#151515",
              surface = "#202020",
              active  = "#303030",
              fg      = "#d8d8d8",
              muted   = "#888888",
              accent  = "#8197bf",
              red     = "#cf6a4c",
              green   = "#99ad6a",
              border  = "#383838",
          }

          require("barbar").setup({
              animation = true,

              auto_hide = false,
              tabpages = false,
              clickable = true,
              focus_on_close = "left",

              insert_at_end = true,
              insert_at_start = false,

              maximum_padding = 1,
              minimum_padding = 1,
              maximum_length = 24,

              semantic_letters = true,

              sidebar_filetypes = {
                  NvimTree = {
                      text = "Explorer",
                      align = "center",
                  },
                  neo_tree = {
                      text = "Explorer",
                      align = "center",
                  },
                  ["neo-tree"] = {
                      text = "Explorer",
                      align = "center",
                  },
                  oil = {
                      text = "Oil",
                      align = "center",
                  },
              },

              icons = {
                  buffer_index = false,
                  buffer_number = false,

                  button = "×",
                  diagnostics = {
                      [vim.diagnostic.severity.ERROR] = {
                          enabled = true,
                          icon = "●",
                      },
                      [vim.diagnostic.severity.WARN] = {
                          enabled = true,
                          icon = "●",
                      },
                      [vim.diagnostic.severity.INFO] = {
                          enabled = true,
                          icon = "●",
                      },
                      [vim.diagnostic.severity.HINT] = {
                          enabled = true,
                          icon = "●",
                      },
                  },

                  gitsigns = {
                      added = {
                          enabled = false,
                          icon = "+",
                      },
                      changed = {
                          enabled = false,
                          icon = "~",
                      },
                      deleted = {
                          enabled = false,
                          icon = "-",
                      },
                  },

                  filetype = {
                      custom_colors = true,
                      enabled = false,
                  },

                  separator = {
                      left = " ",
                      right = " ",
                  },

                  separator_at_end = false,

                  modified = {
                      button = "●",
                  },

                  pinned = {
                      button = "",
                      filename = true,
                      separator = {
                          right = " ",
                      },
                  },
              },

              exclude_ft = {
                  "alpha",
                  "dashboard",
                  "help",
                  "lazy",
                  "notify",
                  "toggleterm",
              },

              exclude_name = {
                  "NvimTree",
              },
          })

          -- Jellybeans highlights
          local function highlights()
              local groups = {
                  BufferCurrent = {
                      fg = colors.fg,
                      bg = colors.active,
                      bold = true,
                  },
                  BufferCurrentIndex = {
                      fg = colors.accent,
                      bg = colors.active,
                  },
                  BufferCurrentSign = {
                      fg = colors.accent,
                      bg = colors.active,
                  },
                  BufferCurrentMod = {
                      fg = colors.green,
                      bg = colors.active,
                  },
                  BufferCurrentTarget = {
                      fg = colors.red,
                      bg = colors.active,
                      bold = true,
                  },

                  BufferVisible = {
                      fg = colors.muted,
                      bg = colors.surface,
                  },
                  BufferVisibleIndex = {
                      fg = colors.muted,
                      bg = colors.surface,
                  },
                  BufferVisibleSign = {
                      fg = colors.border,
                      bg = colors.surface,
                  },
                  BufferVisibleMod = {
                      fg = colors.accent,
                      bg = colors.surface,
                  },

                  BufferInactive = {
                      fg = colors.muted,
                      bg = colors.bg,
                  },
                  BufferInactiveIndex = {
                      fg = colors.muted,
                      bg = colors.bg,
                  },
                  BufferInactiveSign = {
                      fg = colors.border,
                      bg = colors.bg,
                  },
                  BufferInactiveMod = {
                      fg = colors.accent,
                      bg = colors.bg,
                  },

                  BufferTabpages = {
                      fg = colors.fg,
                      bg = colors.bg,
                  },
                  BufferTabpageFill = {
                      bg = colors.bg,
                  },
                  BufferOffset = {
                      fg = colors.muted,
                      bg = colors.bg,
                  },
              }

              for name, opts in pairs(groups) do
                  vim.api.nvim_set_hl(0, name, opts)
              end
          end

          highlights()

          vim.api.nvim_create_autocmd("ColorScheme", {
              group = vim.api.nvim_create_augroup(
                  "KuroBarbarHighlights",
                  { clear = true }
              ),
              callback = highlights,
          })

          -- New file / buffer
          local function new_buffer()
              vim.cmd("enew")
          end

          -- Keymaps
          local keys = {
              ["<leader>tn"] = {
                  new_buffer,
                  "New file",
              },
              ["<leader>tc"] = {
                  "<cmd>BufferClose<CR>",
                  "Close buffer",
              },
              ["<leader>tl"] = {
                  "<cmd>BufferNext<CR>",
                  "Next buffer",
              },
              ["<leader>th"] = {
                  "<cmd>BufferPrevious<CR>",
                  "Previous buffer",
              },
              ["<leader>to"] = {
                  "<cmd>BufferCloseAllButCurrent<CR>",
                  "Close other buffers",
              },
              ["<leader>tr"] = {
                  "<cmd>BufferMoveNext<CR>",
                  "Move buffer right",
              },
              ["<leader>tR"] = {
                  "<cmd>BufferMovePrevious<CR>",
                  "Move buffer left",
              },
          }

          for key, value in pairs(keys) do
              vim.keymap.set("n", key, value[1], {
                  desc = value[2],
              })
          end

          -- Mouse support
          vim.opt.mouse = "a"
      end,
  },


  -- Indent guides
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      indent = { char = '│', smart_indent_cap = true },
      scope = { enabled = true, char = '│' },
      exclude = {
        filetypes = { 'help', 'alpha', 'notify', 'oil', 'terminal', 'lazy', 'diffview' },
      },
    },
  },

  -- Notifications
  {
    'rcarriga/nvim-notify',
    event = 'VeryLazy',
    opts = {
      stages = 'fade_in_slide_out',
      timeout = 3000,
      max_height = function()
        return math.floor(vim.o.lines * 0.75)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.4)
      end,
      background_colour = 'NormalFloat',
    },
    config = function(_, opts)
      local notify = require('notify')
      notify.setup(opts)
      vim.notify = notify
    end,
  },

  -- Scrollbar (v2: native search marks, no hlslens needed)
  {
    'petertriho/nvim-scrollbar',
    event = 'VeryLazy',
    opts = {
      exclude = {
        buftypes = { terminal = true },
        filetypes = { NvimTree = true, alpha = true, notify = true, oil = true },
      },
      providers = {
        gitsigns = true,
      },
      scrollbar = {
        preset = 'minimal',
        autohide = true,
        thumb = { text = '█', blend = 20 },
      },
    },
  },

  -- Start screen
  {
    'goolord/alpha-nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local alpha = require('alpha')
      local dashboard = require('alpha.themes.dashboard')

      dashboard.section.header.val = {
        '',
        '',
        '',
        '',
        '',
        '   ███╗   ██╗ ███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗',
        '   ████╗  ██║ ██╔════╝██╔═══██╗██║   ██║██║████╗ ████║',
        '   ██╔██╗ ██║ █████╗  ██║   ██║██║   ██║██║██╔████╔██║',
        '   ██║╚██╗██║ ██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║',
        '   ██║ ╚████║ ███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║',
        '   ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝',
      }
      dashboard.section.header.opts.hl = 'AlphaHeader'

      dashboard.section.buttons.val = {
        dashboard.button('f', '  Find file', ':Telescope find_files<CR>'),
        dashboard.button('r', '  Recent files', ':Telescope oldfiles<CR>'),
        dashboard.button('g', '  Live grep', ':Telescope live_grep<CR>'),
        dashboard.button('n', '  New file', ':enew<CR>'),
        dashboard.button('t', '  Change theme', ':KuroTheme<CR>'),
        dashboard.button('q', '  Quit Neovim', ':qa<CR>'),
      }
      dashboard.section.buttons.opts.hl = 'AlphaButtons'

      dashboard.section.footer.opts.hl = 'AlphaFooter'
      dashboard.section.footer.val = '  ' .. vim.fn.hostname() .. ' · ' .. os.date('%a %d %b')

      alpha.setup(dashboard.opts)
    end,
  },
}
