{ pkgs, lib, config, ... }:
let
  colors = config.lib.stylix.colors;
  colorNames = [
    "base00" "base01" "base02" "base03"
    "base04" "base05" "base06" "base07"
    "base08" "base09" "base0A" "base0B"
    "base0C" "base0D" "base0E" "base0F"
  ];
  colorValues = map (name: colors.${name}) colorNames;
  initLua = lib.replaceStrings
    (map (name: "@${name}@") colorNames)
    colorValues
    (builtins.readFile ./monovim.lua);

  monovimRuntime = pkgs.runCommand "monovim-vendored-runtime" { pname = "monovim-vendored-runtime"; } ''
    mkdir -p "$out/lua" "$out/colors"
    cp -r ${./monovim/fork/core/lua}/. "$out/lua/"
    chmod -R u+w "$out"
    cp -r ${./monovim/fork/ui/lua}/. "$out/lua/"
    chmod -R u+w "$out"
    cp -r ${./monovim/fork/base46/lua}/. "$out/lua/"
    chmod -R u+w "$out"
    cp -r ${./monovim/fork/ui/colors}/. "$out/colors/"
    chmod -R u+w "$out"
  '';

  plugins = with pkgs.vimPlugins; [
    monovimRuntime
    plenary-nvim
    nvim-web-devicons
    telescope-nvim
    telescope-fzf-native-nvim
    nvim-tree-lua
    indent-blankline-nvim
    comment-nvim
    oil-nvim
    which-key-nvim
    gitsigns-nvim
    vim-fugitive
    lualine-nvim
    nvim-autopairs
    nvim-lspconfig
    nvim-cmp
    cmp-nvim-lsp
    cmp-buffer
    cmp-path
    cmp-cmdline
    luasnip
    cmp_luasnip
    friendly-snippets
    conform-nvim
    alpha-nvim
    (nvim-treesitter.withPlugins (p: [
      p.lua p.vim p.vimdoc p.query p.nix
      p.json p.yaml p.python p.bash p.markdown p.markdown_inline
      p.toml p.java p.dart
    ]))
  ];

  nvim = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
    luaRcContent = initLua;
    inherit plugins;
    withPython3 = true;
    withNodeJs = false;
    extraPython3Packages = ps: [ ps.pynvim ];
  };

  monovim = pkgs.runCommand "monovim-${nvim.version}" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta = {
      description = "Standalone, Nix-built Monovim Neovim distribution";
      mainProgram = "monovim";
    };
  } ''
    mkdir -p "$out/bin"
    makeWrapper ${nvim}/bin/nvim "$out/bin/monovim" --set NVIM_APPNAME monovim
    ln -s monovim "$out/bin/nvim"
    ln -s monovim "$out/bin/vim"
    ln -s monovim "$out/bin/vi"
  '';

  languageTools = with pkgs; [
    bash-language-server
    nil
    lua-language-server
    pyright
    marksman
    taplo
    yaml-language-server
    jdt-language-server
    kotlin-language-server
    stylua
    nixfmt
    shfmt
    shellcheck
    ruff
  ];
in
{
  home.packages = [ monovim ] ++ languageTools;
}
