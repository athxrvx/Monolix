local autocmd = vim.api.nvim_create_autocmd
local config = require "monovim_config"

-- load monodash only on empty file
if config.monodash.load_on_startup then
  local opening_file = vim.api.nvim_buf_get_name(0)
  local is_dir = vim.fn.isdirectory(opening_file) == 1
  local bufmodifed = vim.api.nvim_get_option_value("modified", { buf = 0 })

  if not bufmodifed and (is_dir or opening_file == "") then
    local current_buffer = vim.api.nvim_get_current_buf()
    require("monovim.monodash").open()
    vim.api.nvim_buf_delete(current_buffer, { force = true, unload = false })
  end
end

if config.lsp.signature then
  autocmd("LspAttach", {
    callback = function(args)
      vim.schedule(function()
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if client then
          local signatureProvider = client.server_capabilities.signatureHelpProvider
          if signatureProvider and signatureProvider.triggerCharacters then
            require("monovim.lsp.signature").setup(client, args.buf)
          end
        end
      end)
    end,
  })
end

-- reload the plugin!
autocmd("BufWritePost", {
  pattern = vim.tbl_map(function(path)
    return vim.fs.normalize(vim.uv.fs_realpath(path))
  end, vim.fn.glob(vim.fn.stdpath "config" .. "/lua/**/*.lua", true, true, true)),
  group = vim.api.nvim_create_augroup("ReloadMonovim", {}),

  callback = function(opts)
    local fp = vim.fn.fnamemodify(vim.fs.normalize(vim.api.nvim_buf_get_name(opts.buf)), ":r") --[[@as string]]
    local app_name = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME or "nvim"
    local module = string.gsub(fp, "^.*/" .. app_name .. "/lua/", ""):gsub("/", ".")

    require("monovim.utils").reload(module)
    -- vim.cmd("redraw!")
  end,
})

if config.colorify.enabled then
  require("monovim.colorify").run()
end

local dir = vim.fn.stdpath "data" .. "/mononotify1"

if not vim.uv.fs_stat(dir) then
  vim.fn.mkdir(dir, "p")
  require "monovim.winmes" {
    { "* Blink.cmp plugin integration has been added, will be tested for 2 months" },
    { " " },
    { '* { import = "monovim.blink.lazyspec" } in your plugins file' },
    { " " },
    { "* Discuss at https://github.com/Monovim/Monovim/discussions/3244" },
  }
end
