{ ... }:
{
  imports = [
    ./environment.nix
    ./development.nix
    ../config/shell/fastfetch.nix
    ../config/shell/zsh/zsh.nix
    ../config/shell/athena/mono.nix
    ../config/terminal/tmux/tmux.nix
    ../config/apps/chromium/chromium.nix
  ];
}
