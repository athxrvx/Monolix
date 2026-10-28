pcall(function()
  dofile(vim.g.monovim_base46_cache .. "syntax")
  dofile(vim.g.monovim_base46_cache .. "treesitter")
end)

return {
  ensure_installed = { "lua", "luadoc", "printf", "vim", "vimdoc" },
}
