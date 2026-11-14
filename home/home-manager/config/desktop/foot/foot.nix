{ ... }:
let
  theme = import ../../../theme/theme.nix { };
  colors = theme.colors;
  hex = color: "#${color}";
in
{
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        font = "Iosevka Nerd Font:pixelsize=14";
        font-bold = "Iosevka Nerd Font:pixelsize=14";
        pad = "10x10";
        shell = "zsh";
      };
      scrollback = {
        lines = "4096";
        multiplier = "1";
      };
      cursor = {
        style = "block";
        blink = "no";
      };
      mouse.hide-when-typing = "yes";
      colors = {
        alpha = "1.0";
        background = hex colors.bg;
        foreground = hex colors.fg;
        regular0 = hex colors.c0;
        regular1 = hex colors.c1;
        regular2 = hex colors.c2;
        regular3 = hex colors.c3;
        regular4 = hex colors.c4;
        regular5 = hex colors.c5;
        regular6 = hex colors.c6;
        regular7 = hex colors.c7;
        bright0 = hex colors.c8;
        bright1 = hex colors.c9;
        bright2 = hex colors.c10;
        bright3 = hex colors.c11;
        bright4 = hex colors.c12;
        bright5 = hex colors.c13;
        bright6 = hex colors.c14;
        bright7 = hex colors.c15;
      };
    };
  };
}
