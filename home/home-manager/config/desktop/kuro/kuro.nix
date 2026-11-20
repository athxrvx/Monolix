{ pkgs, ... }:
let
  kurogen = import ./kurogen.nix { inherit pkgs; };
in
{
  # The source of truth is the imperative ~/.config/kuro/kuro.toml, with
  # themes in ~/.config/kuro/themes/*.toml. Home Manager owns none of it.
  # kurogen seeds those files on first run from the bundled copies in the
  # store (KURO_DEFAULTS) and `kurogen set` rewrites kuro.toml in place.
  home.packages = [ kurogen ];
}
