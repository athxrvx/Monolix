-- Monovim: a small, fast Neovim distro managed entirely by Nix.
-- Palette tokens are filled from Stylix so the editor follows the desktop theme.
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
vim.g.monovim_base46_cache = vim.fn.stdpath("data") .. "/monovim/base46/"

package.preload["monovimrc"] = function()
  return {
    monovim_base46 = {
      theme = "yoru",
      transparency = false,
      theme_toggle = { "yoru", "yoru" },
      integrations = { "alpha" },
    },
    ui = {
      statusline = { enabled = true, theme = "default", separator_style = "round" },
      tabufline = { enabled = true, lazyload = false },
    },
    monodash = { load_on_startup = false },
  }
end

require("monovim_base46").load_all_highlights()
vim.cmd.colorscheme("monovim")
require("monovim.options")
require("monovim")
require("monovim.mappings")

require("nvim-tree").setup(require("monovim.configs.nvimtree"))

local c = {
  base00 = "#@base00@", base01 = "#@base01@", base02 = "#@base02@", base03 = "#@base03@",
  base04 = "#@base04@", base05 = "#@base05@", base06 = "#@base06@", base07 = "#@base07@",
  base08 = "#@base08@", base09 = "#@base09@", base0A = "#@base0A@", base0B = "#@base0B@",
  base0C = "#@base0C@", base0D = "#@base0D@", base0E = "#@base0E@", base0F = "#@base0F@",
}

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.updatetime = 250
opt.timeoutlen = 400
opt.splitright = true
opt.splitbelow = true
opt.ignorecase = true
opt.smartcase = true
opt.completeopt = { "menu", "menuone", "noselect" }
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.undofile = true
opt.confirm = true

vim.api.nvim_set_hl(0, "Normal", { fg = c.base05, bg = c.base00 })
vim.api.nvim_set_hl(0, "NormalFloat", { fg = c.base05, bg = c.base01 })
vim.api.nvim_set_hl(0, "FloatBorder", { fg = c.base03, bg = c.base01 })
vim.api.nvim_set_hl(0, "CursorLine", { bg = c.base01 })
vim.api.nvim_set_hl(0, "LineNr", { fg = c.base03 })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = c.base0D, bold = true })
vim.api.nvim_set_hl(0, "Visual", { bg = c.base02 })
vim.api.nvim_set_hl(0, "Search", { fg = c.base00, bg = c.base0A })
vim.api.nvim_set_hl(0, "DiagnosticError", { fg = c.base08 })
vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = c.base09 })
vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = c.base0C })
vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = c.base0D })
vim.api.nvim_set_hl(0, "Pmenu", { fg = c.base05, bg = c.base01 })
vim.api.nvim_set_hl(0, "PmenuSel", { fg = c.base00, bg = c.base0D, bold = true })

local map = vim.keymap.set
local function desc(label)
  return { desc = label, silent = true }
end

map("n", "<Esc>", "<cmd>nohlsearch<CR>", desc("Clear search highlight"))
map("n", "<leader>w", "<cmd>write<CR>", desc("Save file"))
map("n", "<leader>q", "<cmd>confirm quit<CR>", desc("Quit"))
map("n", "<leader>e", "<cmd>Oil<CR>", desc("File browser"))
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", desc("Find files"))
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", desc("Search in project"))
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", desc("Open buffers"))
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc("Recent files"))
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", desc("Help"))
map("n", "<leader>gg", "<cmd>Git<CR>", desc("Git status"))
map("n", "<leader>F", function() vim.lsp.buf.format({ async = true }) end, desc("Format file"))
map("n", "<leader>fw", "<cmd>Telescope grep_string<CR>", desc("Find word under cursor"))
map("n", "<leader>c", "<cmd>bd<CR>", desc("Close buffer"))
map("n", "<leader>bd", "<cmd>bdelete<CR>", desc("Delete buffer"))
map("n", "<leader>fR", function() vim.lsp.buf.rename() end, desc("Rename symbol"))
map("n", "<leader>ca", function() vim.lsp.buf.code_action() end, desc("Code action"))
map("n", "gd", function() vim.lsp.buf.definition() end, desc("Go to definition"))
map("n", "gD", function() vim.lsp.buf.declaration() end, desc("Go to declaration"))
map("n", "gr", function() vim.lsp.buf.references() end, desc("Find references"))
map("n", "K", function() vim.lsp.buf.hover() end, desc("Hover documentation"))
map("n", "<leader>r", "<cmd>!flutter run<CR>", desc("Run Flutter app"))

require("which-key").setup({})
require("gitsigns").setup({})
require("nvim-autopairs").setup({})
require("oil").setup({
  view_options = { show_hidden = true },
  keymaps = { ["q"] = "actions.close" },
})
require("lualine").setup({
  options = {
    theme = {
      normal = { a = { fg = c.base00, bg = c.base0D, gui = "bold" }, b = { fg = c.base05, bg = c.base02 }, c = { fg = c.base04, bg = c.base01 } },
      insert = { a = { fg = c.base00, bg = c.base0B, gui = "bold" } },
      visual = { a = { fg = c.base00, bg = c.base0E, gui = "bold" } },
      replace = { a = { fg = c.base00, bg = c.base08, gui = "bold" } },
      command = { a = { fg = c.base00, bg = c.base09, gui = "bold" } },
      inactive = { a = { fg = c.base04, bg = c.base01 }, b = { fg = c.base04, bg = c.base01 }, c = { fg = c.base04, bg = c.base01 } },
    },
    section_separators = { left = "", right = "" },
    component_separators = { left = "│", right = "│" },
    globalstatus = true,
  },
})

local dashboard = require("alpha.themes.dashboard")
dashboard.section.header.val = {
  "  ███╗   ███╗ ██████╗ ███╗   ██╗ ██████╗ ██╗   ██╗██╗███╗   ███╗  ",
  "  ████╗ ████║██╔═══██╗████╗  ██║██╔═══██╗██║   ██║██║████╗ ████║  ",
  "  ██╔████╔██║██║   ██║██╔██╗ ██║██║   ██║██║   ██║██║██╔████╔██║  ",
  "  ██║╚██╔╝██║██║   ██║██║╚██╗██║██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║  ",
  "  ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║  ",
  "  ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝  ",
}
dashboard.section.header.opts.hl = "Title"
dashboard.section.buttons.val = {
  dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
  dashboard.button("g", "󰱼  Search project", ":Telescope live_grep<CR>"),
  dashboard.button("r", "  Recent files", ":Telescope oldfiles<CR>"),
  dashboard.button("e", "󰙅  Browse files", ":Oil<CR>"),
  dashboard.button("q", "󰅚  Quit", ":quit<CR>"),
}
dashboard.section.buttons.opts.hl = "String"
dashboard.section.footer.val = "Monovim • a Nix-managed development environment"
dashboard.section.footer.opts.hl = "Comment"
require("alpha").setup(dashboard.config)

local cmp = require("cmp")
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()
cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({ { name = "nvim_lsp" }, { name = "luasnip" }, { name = "path" } }, { { name = "buffer" } }),
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()
vim.lsp.config("*", { capabilities = capabilities })
vim.lsp.config("lua_ls", { settings = { Lua = { diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false } } } })
vim.lsp.config("nil_ls", { settings = { ["nil"] = { formatting = { command = { "nixfmt" } } } } })
vim.lsp.config("dartls", { cmd = { "dart", "language-server", "--protocol=lsp" } })
vim.lsp.enable({
  "bashls", "nil_ls", "lua_ls", "jsonls",
  "pyright", "marksman", "taplo", "yamlls", "jdtls", "kotlin_language_server", "dartls",
})

require("nvim-treesitter").setup({})
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    nix = { "nixfmt" },
    python = { "ruff_format" },
    sh = { "shfmt" },
    bash = { "shfmt" },
  },
  format_on_save = { timeout_ms = 1500, lsp_format = "fallback" },
})

vim.diagnostic.config({
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  signs = true,
  virtual_text = { spacing = 2, source = "if_many" },
})
