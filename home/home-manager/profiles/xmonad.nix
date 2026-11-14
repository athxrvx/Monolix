{ pkgs, ... }:
let
  theme = import ../theme/theme.nix { };
  source = builtins.readFile ../config/desktop/xmonad/xmonad.hs;
  themedConfig = pkgs.writeText "xmonad-athena.hs" (builtins.replaceStrings
    [ "@FOCUSED_BORDER@" "@NORMAL_BORDER@" ]
    [ "#${theme.colors.primary}" "#${theme.colors.c8}" ]
    source);
in
{
  xsession.windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
    config = themedConfig;
  };

  home.packages = with pkgs; [
    picom
    xmobar
    xclip
    imagemagick
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono
  ];

  imports = [
    ../config/desktop/kitty/kitty.nix
  ];
  home.sessionVariables.TERMINAL = "kitty";
}
