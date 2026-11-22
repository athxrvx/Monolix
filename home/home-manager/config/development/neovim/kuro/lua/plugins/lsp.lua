local registry = require('config.lsp')

return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'hrsh7th/cmp-nvim-lsp',
  },
  config = function()
    local capabilities = require('cmp_nvim_lsp').default_capabilities()

    for server, config in pairs(registry.servers) do
      vim.lsp.config(server, vim.tbl_deep_extend('force', {
        capabilities = capabilities,
      }, config))
      vim.lsp.enable(server)
    end

    -- Buffer-local keymaps, available whenever a language server attaches.
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('UserLspKeymaps', { clear = true }),
      callback = function(ev)
        local buf = ev.buf
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
        end

        map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
        map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
        map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
        map('n', 'gr', vim.lsp.buf.references, 'Find references')
        map('n', 'K', vim.lsp.buf.hover, 'Hover documentation')
        map('n', '<C-k>', vim.lsp.buf.signature_help, 'Signature help')
        map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
        map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, 'Code action')
        map('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, 'Format buffer')
        map('v', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, 'Format selection')
        map('n', '[d', vim.diagnostic.goto_prev, 'Previous diagnostic')
        map('n', ']d', vim.diagnostic.goto_next, 'Next diagnostic')
        map('n', '<leader>d', vim.diagnostic.open_float, 'Show line diagnostic')
        map('n', '<leader>D', function()
          require('telescope.builtin').diagnostics()
        end, 'All diagnostics')

        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client.supports_method('textDocument/inlayHint') then
          vim.lsp.inlay_hint.enable(true, { bufnr = buf })
        end
      end,
    })
  end,
}
