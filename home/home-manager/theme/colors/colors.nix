{ lib, ... }:
let
  root = ./.;
  # One TOML file per theme definition. Adding a theme is adding a file here.
  themes = lib.filter
    (p: lib.hasSuffix ".toml" (toString p))
    (lib.filesystem.listFilesRecursive root);
  relative = p: lib.removePrefix (toString root + "/") (toString p);
in
{
  # Theme definitions are managed by Nix and installed read-only.
  # The active theme is an imperative setting in ~/.config/kuro/kuro.toml,
  # changed with `kurogen set theme.scheme <name>`.
  home.file = lib.listToAttrs (map (p: {
    name = ".config/kuro/themes/${relative p}";
    value.source = p;
  }) themes);
}
