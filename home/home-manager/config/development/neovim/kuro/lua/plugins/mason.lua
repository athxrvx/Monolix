-- Mason: install and manage language servers, formatters and linters.
-- Nothing is installed automatically; use <leader>cI for the web + Rust set
-- or <leader>cm / :MasonInstall to pick individual packages.
local registry = require('config.lsp')

local function install_scoped_tools()
  local servers = vim.tbl_keys(registry.servers)
  vim.cmd('LspInstall ' .. table.concat(servers, ' '))

  if #registry.tools > 0 then
    vim.cmd('MasonInstall ' .. table.concat(registry.tools, ' '))
  end

  vim.notify('Installing web + Rust tools: ' .. table.concat(servers, ', '), vim.log.levels.INFO)
end

return {
  'mason-org/mason.nvim',
  lazy = false,
  priority = 1001,
  dependencies = {
    'mason-org/mason-lspconfig.nvim',
  },
  keys = {
    { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason: manage tools' },
    { '<leader>cU', '<cmd>MasonUpdate<cr>', desc = 'Mason: update registry' },
    { '<leader>ci', '<cmd>MasonInstall<cr>', desc = 'Mason: install package' },
    { '<leader>cI', install_scoped_tools, desc = 'Mason: install web + Rust tools' },
  },
  opts = {
    ui = {
      border = 'rounded',
      width = 0.8,
      height = 0.8,
      icons = {
        package_installed = '✓',
        package_pending = '➜',
        package_uninstalled = '✗',
      },
      keymaps = {
        toggle_package_expand = '<CR>',
        install_package = 'i',
        update_package = 'u',
        check_package_version = 'c',
        update_all_packages = 'U',
        check_outdated_packages = 'C',
        uninstall_package = 'X',
        cancel_installation = '<C-c>',
        apply_language_filter = '<C-f>',
      },
    },
    registries = {
      'github:mason-org/mason-registry',
    },
  },
  config = function(_, opts)
    require('mason').setup(opts)

    require('mason-lspconfig').setup({
      -- Install manually with <leader>cI or :LspInstall <server>.
      automatic_installation = false,
      -- Servers are enabled explicitly in lua/plugins/lsp.lua.
      automatic_enable = false,
    })

    vim.api.nvim_create_user_command('KuroInstallTools', install_scoped_tools, {
      desc = 'Install the web + Rust servers and tools from config.lsp',
    })
  end,
}
