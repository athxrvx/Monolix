{ pkgs, ... }:
{
  # The static kitty.conf is installed from beside this module. It includes
  # ~/.config/kitty/kuro.conf, which kurogen generates from ~/.config/kuro.
  # Home Manager does not own kuro.conf.
  home.packages = [ pkgs.kitty ];
  home.file.".config/kitty/kitty.conf".source = ./kitty.conf;
}
