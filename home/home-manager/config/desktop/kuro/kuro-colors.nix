# Static fallback palette for tools configured at Nix eval time.
# Derived from the same declarative theme definitions and kuro.toml that
# kurogen uses, so there is no second hand-maintained palette. The active
# values still come from ~/.config/kuro/kuro.toml at runtime.
let
  theme = builtins.fromTOML (builtins.readFile ../../../theme/colors/jellybeans.toml);
  settings = builtins.fromTOML (builtins.readFile ./kuro.toml);
in
{
  base00 = theme.background;
  base01 = theme.dark_background;
  base02 = theme.lighter_background;
  base03 = theme.muted;
  base04 = theme.muted;
  base05 = theme.foreground;
  base06 = theme.light_foreground;
  base07 = theme.bright_foreground;
  base08 = theme.red;
  base09 = theme.yellow;
  base0A = theme.orange;
  base0B = theme.green;
  base0C = theme.cyan;
  base0D = theme.blue;
  base0E = theme.magenta;
  base0F = theme.brown;

  uiFont = settings.fonts.ui_family;
  monoFont = settings.fonts.terminal_family;
}
