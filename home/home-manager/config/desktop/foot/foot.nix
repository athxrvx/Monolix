{ ... }:
let
  # Static fallback palette mirroring Kuro's bundled jellybeans theme. The
  # active palette still comes from ~/.config/kuro/kuro.toml for apps that can
  # read ~/.cache/kuro/theme.json; Nix only needs values at eval time.
  colors = import ../kuro/kuro-colors.nix;
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
        background = colors.base00;
        foreground = colors.base05;
        regular0 = colors.base00;
        regular1 = colors.base08;
        regular2 = colors.base09;
        regular3 = colors.base0A;
        regular4 = colors.base0B;
        regular5 = colors.base0C;
        regular6 = colors.base0D;
        regular7 = colors.base0E;
        bright0 = colors.base03;
        bright1 = colors.base08;
        bright2 = colors.base09;
        bright3 = colors.base0A;
        bright4 = colors.base0B;
        bright5 = colors.base0C;
        bright6 = colors.base0D;
        bright7 = colors.base0E;
      };
    };
  };
}
