local map = vim.keymap.set
local opts = { silent = true }

-- Save / quit
map('n', '<leader>w', '<cmd>write<cr>', { desc = 'Save file', silent = true })
map('n', '<leader>W', '<cmd>wall<cr>', { desc = 'Save all files', silent = true })
map('n', '<leader>q', '<cmd>quit<cr>', { desc = 'Quit', silent = true })
map('n', '<leader>Q', '<cmd>quitall<cr>', { desc = 'Quit all', silent = true })
map('n', '<leader>x', '<cmd>write<bar>quit<cr>', { desc = 'Save and quit', silent = true })

-- Window navigation
map('n', '<C-h>', '<C-w>h', opts)
map('n', '<C-j>', '<C-w>j', opts)
map('n', '<C-k>', '<C-w>k', opts)
map('n', '<C-l>', '<C-w>l', opts)

-- Split resizing
map('n', '<M-h>', '<cmd>vertical resize -2<cr>', opts)
map('n', '<M-j>', '<cmd>resize -2<cr>', opts)
map('n', '<M-k>', '<cmd>resize +2<cr>', opts)
map('n', '<M-l>', '<cmd>vertical resize +2<cr>', opts)

-- Move text in visual mode
map('v', 'J', ":move '>+1<CR>gv=gv", opts)
map('v', 'K', ":move '<-2<CR>gv=gv", opts)
map('v', '<', '<gv', opts)
map('v', '>', '>gv', opts)

-- Keep cursor centred when searching / scrolling
map('n', '<C-d>', '<C-d>zz', opts)
map('n', '<C-u>', '<C-u>zz', opts)
map('n', 'n', 'nzzzv', opts)
map('n', 'N', 'Nzzzv', opts)

-- Better paste: don't clobber the unnamed register
map('x', '<leader>p', '"_dP', opts)

-- Clear search highlight / escape terminal
map('n', '<Esc>', '<cmd>nohlsearch<cr>', opts)
map('t', '<Esc>', '<C-\\><C-n>', opts)

-- Theme picker
map('n', '<leader>th', '<cmd>KuroTheme<cr>', { desc = 'Change theme', silent = true })

-- VSCode-style keybindings ---------------------------------------------------
local vs = { silent = true }

-- Files & search
map({ 'n', 'i' }, '<C-s>', '<Esc><cmd>write<cr>', { desc = 'VSCode: Save', silent = true })
map('n', '<C-p>', function()
  require('telescope.builtin').find_files({ hidden = true })
end, { desc = 'VSCode: Quick open', silent = true })
map('n', '<C-S-p>', '<cmd>Telescope commands<cr>', { desc = 'VSCode: Command palette', silent = true })
map('n', '<C-S-f>', function()
  require('telescope.builtin').live_grep()
end, { desc = 'VSCode: Search in files', silent = true })
map('n', '<C-f>', '/', { desc = 'VSCode: Find in buffer', silent = true })
map('n', '<C-g>', '<cmd>Telescope current_buffer_fuzzy_find<cr>', { desc = 'VSCode: Find in file', silent = true })

-- Editing
map('n', '<C-a>', 'ggVG', { desc = 'VSCode: Select all', silent = true })
map('n', '<C-z>', 'u', { desc = 'VSCode: Undo', silent = true })
map('n', '<C-S-z>', '<C-r>', { desc = 'VSCode: Redo', silent = true })
map('n', '<C-y>', '<C-r>', { desc = 'VSCode: Redo', silent = true })
map('n', '<C-S-k>', 'dd', { desc = 'VSCode: Delete line', silent = true })
map('n', '<C-/>', function()
  require('Comment.api').toggle.linewise.current()
end, { desc = 'VSCode: Toggle comment', silent = true })
map('x', '<C-/>', function()
  require('Comment.api').toggle.linewise(vim.fn.visualmode())
end, { desc = 'VSCode: Toggle comment', silent = true })
map('n', '<M-Up>', ":move -2<CR>==", { desc = 'VSCode: Move line up', silent = true })
map('n', '<M-Down>', ":move +1<CR>==", { desc = 'VSCode: Move line down', silent = true })

-- Panels & buffers
map('n', '<C-b>', '<cmd>NvimTreeToggle<cr>', { desc = 'VSCode: Toggle sidebar', silent = true })
map('n', '<C-t>', '<cmd>ToggleTerm<cr>', { desc = 'VSCode: Toggle terminal', silent = true })
map('n', '<C-S-b>', '<cmd>AerialToggle<cr>', { desc = 'VSCode: Toggle outline', silent = true })
map('n', '<C-Tab>', '<cmd>BufferLineCycleNext<cr>', { desc = 'VSCode: Next tab', silent = true })
map('n', '<C-S-Tab>', '<cmd>BufferLineCyclePrev<cr>', { desc = 'VSCode: Previous tab', silent = true })

-- LSP (VSCode equivalents)
map('n', '<F2>', vim.lsp.buf.rename, { desc = 'VSCode: Rename symbol', silent = true })
map('n', '<F12>', vim.lsp.buf.definition, { desc = 'VSCode: Go to definition', silent = true })
map('n', '<S-F12>', vim.lsp.buf.references, { desc = 'VSCode: Find references', silent = true })
map('n', '<C-.>', vim.lsp.buf.code_action, { desc = 'VSCode: Quick fix', silent = true })
map('n', 'K', vim.lsp.buf.hover, { desc = 'VSCode: Show hover', silent = true })
map('n', '<C-S-o>', '<cmd>AerialToggle<cr>', { desc = 'VSCode: Go to symbol', silent = true })
