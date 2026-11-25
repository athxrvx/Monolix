{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Source control and project archives.
    git
    wget
    unzip

    # CLI toolchains and the configured editor.
    helix
    gcc
    gnumake
    pkg-config
    python3
    rustc
    cargo

    # Search, inspection, and codebase analysis.
    ripgrep
    fd
    bat
    tokei

    # Language servers and build tools. Heavyweight GUI IDEs and the
    # Android/Java/Flutter stack are intentionally not installed.
    nixd
    python3Packages.python-lsp-server
    rust-analyzer
    gopls
    clang-tools
    typescript-language-server
    bash-language-server
    vscode-langservers-extracted
    eslint
    prettierd
    stylua
    nixfmt
    ruff
    python3Packages.pytest
    shellcheck
    shfmt
    jq
    cmake
    ninja
  ];

  imports = [
    ../config/development/git.nix
    ../config/development/opencode.nix
    ../config/development/helix/helix.nix
  ];
}
