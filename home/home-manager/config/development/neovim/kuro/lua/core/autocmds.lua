local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight text when yanking
augroup('YankHighlight', { clear = true })
autocmd('TextYankPost', {
  group = 'YankHighlight',
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 200 })
  end,
})

-- Trim trailing whitespace on save (skip plain text formats)
augroup('TrimWhitespace', { clear = true })
autocmd('BufWritePre', {
  group = 'TrimWhitespace',
  callback = function()
    if vim.bo.filetype == 'markdown' or vim.bo.filetype == 'text' then
      return
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.api.nvim_win_set_cursor(0, cursor)
  end,
})

-- Close helper windows with q
augroup('CloseWithQ', { clear = true })
autocmd('FileType', {
  group = 'CloseWithQ',
  pattern = { 'help', 'qf', 'man', 'lspinfo', 'checkhealth' },
  callback = function()
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = true, silent = true })
  end,
})

-- Keep splits balanced on terminal resize
autocmd('VimResized', {
  callback = function()
    vim.cmd('tabdo wincmd =')
  end,
})
