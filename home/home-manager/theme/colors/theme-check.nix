{ pkgs, ... }:
let
  themeCheck = pkgs.writeShellApplication {
    name = "kuro-theme-check";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${./check_palettes.py} ${./.}
    '';
  };
in
{
  home.packages = [ themeCheck ];
}
