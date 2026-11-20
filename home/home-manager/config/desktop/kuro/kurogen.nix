# Expression (not a Home Manager module): the kurogen wrapper.
# KURO_DEFAULTS points at bundled first-run defaults: the base kuro.toml from
# beside this file and the Nix-managed theme definitions in theme/colors.
{ pkgs }:
let
  root = ./.;
  defaults = pkgs.linkFarm "kuro-defaults" [
    {
      name = "kuro.toml";
      path = root + "/kuro.toml";
    }
    {
      name = "themes";
      path = ../../../theme/colors;
    }
  ];
in
pkgs.writeShellScriptBin "kurogen" ''
  export KURO_DEFAULTS="${defaults}"
  exec ${pkgs.python3}/bin/python3 "${root}/kurogen.py" "$@"
''
