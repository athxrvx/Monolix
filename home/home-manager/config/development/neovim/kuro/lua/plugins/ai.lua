-- Provider-agnostic AI chat sidebar.
-- Backed by the OpenCode ACP agent by default, so any provider configured in
-- OpenCode works here. HTTP adapters (OpenAI, Anthropic, Gemini, Ollama,
-- OpenRouter, ...) are also available via :CodeCompanionChat adapter=<name>.
return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  cmd = {
    'CodeCompanion',
    'CodeCompanionChat',
    'CodeCompanionActions',
    'CodeCompanionCLI',
    'CodeCompanionCodeReview',
    'CodeCompanionCmd',
  },
  keys = {
    {
      '<C-M-b>',
      '<cmd>CodeCompanionChat Toggle<cr>',
      desc = 'Toggle AI chat sidebar',
      mode = { 'n', 'v' },
    },
    {
      '<leader>ai',
      '<cmd>CodeCompanionChat Toggle<cr>',
      desc = 'Toggle AI chat sidebar',
      mode = { 'n', 'v' },
    },
    {
      '<leader>ac',
      '<cmd>CodeCompanionChat<cr>',
      desc = 'New AI chat',
      mode = { 'n', 'v' },
    },
    {
      '<leader>aa',
      '<cmd>CodeCompanionActions<cr>',
      desc = 'AI action palette',
      mode = { 'n', 'v' },
    },
    {
      '<leader>at',
      '<cmd>CodeCompanionChat Add<cr>',
      desc = 'Add selection to AI chat',
      mode = { 'v' },
    },
  },
  opts = {
    interactions = {
      chat = {
        -- OpenCode is an ACP agent: it uses whatever model/provider you have
        -- configured in OpenCode, so this sidebar is not tied to one vendor.
        adapter = 'opencode',
        roles = {
          llm = function(adapter)
            return adapter.formatted_name .. ' (' .. adapter.name .. ')'
          end,
          user = 'You',
        },
      },
      -- ACP agents only run in the chat buffer; use an HTTP adapter inline.
      inline = {
        adapter = 'openai',
      },
    },
    display = {
      chat = {
        window = {
          layout = 'vertical',
          position = 'right',
          width = 0.35,
          full_height = true,
          sticky = true,
          buflisted = false,
          opts = {
            number = false,
            relativenumber = false,
            signcolumn = 'no',
            wrap = true,
            breakindent = true,
            linebreak = true,
          },
        },
        title = { position = 'winbar' },
        show_header_separator = false,
        start_in_insert_mode = true,
        intro_message = 'Ask anything. #{buffer} shares this file; @{files} lets the AI edit.',
      },
    },
    opts = {
      log_level = 'ERROR',
    },
  },
}
