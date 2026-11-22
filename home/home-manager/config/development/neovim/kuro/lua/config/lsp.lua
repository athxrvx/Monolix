-- Shared LSP / tooling lists used by both Mason and nvim-lspconfig.
-- Scoped to web development and Rust.
local M = {}

M.servers = {
  -- Web
  ts_ls = {},
  html = {},
  cssls = {},
  jsonls = {},
  eslint = {},
  -- Rust
  rust_analyzer = {},
}

-- Non-LSP tools installed through Mason (consumed by conform.nvim).
-- rustfmt is provided by the Rust toolchain, not Mason.
M.tools = {
  'prettierd',
}

return M
