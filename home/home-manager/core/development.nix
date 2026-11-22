{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Source control and project archives.
    git
    wget
    unzip

    # CLI toolchains and editors used by this setup.
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
    shellcheck
    shfmt
    jq
    cmake
    ninja
  ];

  imports = [
    ../config/development/opencode.nix
    # ../config/development/emacs/emacs.nix
    ../config/development/neovim/neovim.nix
  ];
}
