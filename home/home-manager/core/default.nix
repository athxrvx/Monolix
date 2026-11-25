{ ... }:
{
  imports = [
    ./environment.nix
    ./development.nix
    ../config/shell/fastfetch.nix
    ../config/shell/zsh/zsh.nix
    ../config/shell/athena/kuro.nix
    ../config/shell/athena/dynashell.nix
    ../config/terminal/tmux/tmux.nix
    ../config/desktop/qute/qute.nix
    ../config/desktop/xdg/xdg.nix
  ];
}
