{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    # Home Manager builds its own wrapper, so feed it the bare Neovim binary.
    package = pkgs.neovim-unwrapped;
  };

  # Home Manager owns the executable; this development tree remains the live
  # user config under ~/.config/nvim.
  xdg.configFile."nvim".source = ./kuro;

  home.packages = with pkgs; [
    fd
    ripgrep
    gcc
    gnumake
  ];
}
