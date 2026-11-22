local opt = vim.opt

-- Leader keys (set before plugins / keymaps load)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable netrw (oil.nvim replaces it)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Appearance
opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = 'yes'
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣', extends = '›', precedes = '‹' }
opt.fillchars = { eob = ' ', fold = ' ', foldopen = '▾', foldclose = '▸', foldsep = '│', diff = '╱' }

-- Chrome: let lualine own the statusline
opt.laststatus = 3
opt.showmode = false
opt.ruler = false
opt.showcmdloc = 'statusline'
opt.smoothscroll = true
opt.pumheight = 12
opt.pumblend = 10
opt.winblend = 8

-- Folds (powered by Treesitter when a parser is available)
opt.foldmethod = 'expr'
opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
opt.foldtext = 'v:lua.vim.treesitter.foldtext()'
opt.foldlevel = 99
opt.foldnestmax = 3

-- Editing behaviour
opt.mouse = 'a'
opt.clipboard = 'unnamedplus'
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = false
opt.undofile = true
local undo_dir = vim.fn.stdpath('state') .. '/undo'
vim.fn.mkdir(undo_dir, 'p')
opt.undodir = undo_dir
opt.swapfile = false
opt.backup = false
opt.inccommand = 'split'
opt.diffopt:append('linematch:60')
opt.breakindent = true
opt.splitright = true
opt.splitbelow = true
opt.confirm = true
opt.updatetime = 250
opt.timeoutlen = 300

-- Indentation
opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.autoindent = true
opt.smartindent = true

-- Completion
opt.completeopt = 'menu,menuone,noselect'
opt.shortmess:append('c')

-- Diagnostics
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = true },
})
