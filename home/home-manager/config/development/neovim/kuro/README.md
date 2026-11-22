# Neovim config

Modern Lua config for Neovim 0.12, managed with [lazy.nvim](https://github.com/folke/lazy.nvim).

## Structure

```
init.lua                    entry point + lazy bootstrap
lua/core/options.lua        vim options
lua/core/keymaps.lua        global keymaps
lua/core/autocmds.lua       autocommands
lua/plugins/*.lua           plugin specs
lua/kuro-themes/init.lua    custom colorscheme engine
kuro-themes/colors/*.lua    one colorscheme file per palette
```

## Themes

11 custom colorschemes are generated from the TOML palettes in
`~/.config/kuro/themes/`. Embedded copies are used as a fallback if that
directory is unavailable.

- `catppuccin`
- `everforest`
- `gruvbox`
- `jellybeans` **(default)**
- `kanagawa`
- `matte-black`
- `miasma`
- `nord`
- `rose-pine` (light)
- `solitude`
- `tokyo-night`

Switch with `:KuroTheme` (`<leader>th`), `:KuroTheme nord`, or the standard
`:colorscheme nord`. The choice is saved to `~/.local/state/nvim/kuro-theme`.
Change the startup default in `lua/plugins/colorscheme.lua`:

```lua
require('kuro-themes').setup({ default = 'jellybeans' })
```

All 11 palettes style the statusline, tabline, explorer, dashboard, indent
guides, notifications, scrollbar, Flash, Aerial and plugin popups.

## UI

- **Sidebar explorer** — nvim-tree: `<leader>e` toggle, `<leader>ef` reveal file.
  Indent guides (no folder arrows or root label), generous icon padding, a
  two-column left gutter, git state icons, diagnostic markers, opened/modified
  file highlights, a grey focused-row highlight and a subtle divider that
  blends into the editor.
- **Tabs** — bufferline: clickable buffers with diagnostics and git state. The
  tabline is its own tinted surface with a highlighted active tab; a blank
  offset block above the sidebar keeps tabs beside the tree.
- **Modeline / statusline** — lualine: mode, branch, diff, filename, diagnostics,
  search count, active LSP clients, filetype, progress and location
- **Dashboard** — alpha: shown on startup with file/theme shortcuts
- Indent guides (ibl), nvim-notify, nvim-scrollbar v2 (native search marks, no
  hlslens), global statusline, smooth scroll

## AI chat sidebar

CodeCompanion provides a right-side chat sidebar that is not tied to one AI
vendor. `<C-M-b>` (or `<leader>ai`) toggles it; `<leader>ac` starts a new chat.

The default adapter is the local **OpenCode** ACP agent, so any provider you
have configured in OpenCode works immediately. You can also pick any built-in
HTTP adapter on demand:

```
:CodeCompanionChat adapter=anthropic model=claude-haiku-4-5-20251001
:CodeCompanionChat adapter=openai model=gpt-5-mini
:CodeCompanionChat adapter=gemini
:CodeCompanionChat adapter=ollama
```

HTTP adapters read their keys from the usual env vars (`OPENAI_API_KEY`,
`ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, ...). In the chat buffer, `#{buffer}`
shares the current file and `@{files}` allows the AI to edit files. Other
useful maps: `<leader>aa` (action palette), `<leader>at` (add visual selection).

## Mason

Mason manages language servers, formatters and linters. Configuration lives in
`lua/plugins/mason.lua`, with the shared package lists in `lua/config/lsp.lua`.

- Web servers: `ts_ls`, `html`, `cssls`, `jsonls`, `eslint`
- Rust server: `rust_analyzer`
- Tool: `prettierd` (Rust uses `rustfmt` from your toolchain)
- `<leader>cm` opens `:Mason`, `<leader>cU` updates the registry, `<leader>ci` installs a package
- `<leader>cI` / `:KuroInstallTools` installs the web + Rust set on demand

Nothing is installed automatically at startup. Add a server or tool to the
lists in `lua/config/lsp.lua` and use `<leader>cI` to install it. Servers are
enabled explicitly in `lua/plugins/lsp.lua` via `vim.lsp.config` / `vim.lsp.enable`.

## Plugins

Telescope (+ fzf, ui-select, yank history), Treesitter, LSP + Mason, nvim-cmp,
LuaSnip, gitsigns, vim-fugitive, Diffview, Oil, Comment.nvim, autopairs,
which-key, Trouble, Flash, Aerial, nvim-surround, nvim-ts-autotag, ToggleTerm,
Yanky, Persistence, lazydev, Conform, CodeCompanion, and the UI stack above.

Plugins install automatically on first launch. Use `:Lazy` for plugins and
`:Mason` for external tooling.

## Keybindings

| Key | Action |
| --- | --- |
| `<leader>e` | Toggle sidebar explorer |
| `<leader>o` | Open Oil buffer explorer |
| `<leader>ff` / `<leader>fg` | Find files / live grep |
| `<leader>ao` | Toggle code outline (Aerial) |
| `<leader>th` | Theme picker |
| `<C-M-b>` / `<leader>ai` | Toggle AI chat sidebar |
| `<leader>ac` / `<leader>aa` | New AI chat / AI action palette |
| `<C-p>` / `<C-S-p>` | Quick open / command palette (VSCode-style) |
| `<C-s>` / `<C-z>` / `<C-y>` | Save / undo / redo (VSCode-style) |
| `<C-b>` / `<C-t>` | Toggle file tree / terminal (VSCode-style) |
| `<leader>gv` / `<leader>gh` | Diff view / file history |
| `<leader>tt` / `<leader>tf` | Toggle terminal / floating terminal |
| `<leader>yy` | Yank history |
| `s` / `S` | Flash jump / treesitter jump |
| `ys` / `cs` / `ds` | Add / change / delete surroundings |
| `<leader>f` / `<leader>fm` | LSP format / Conform format |
| `<leader>qs` / `<leader>ql` | Save / load session |
| `<leader>xx` | Diagnostics panel |
