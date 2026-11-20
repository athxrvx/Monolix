{ lib, ... }:
let
  root = ./.;
  files = lib.filesystem.listFilesRecursive root;
  relative = p: lib.removePrefix (toString root + "/") (toString p);
in
{
  # All dotfiles are installed by Home Manager. The only imperative file is
  # ~/.config/zsh/custom.zsh, sourced at the end of zshrc for user additions.
  home.file = lib.listToAttrs (map (p: {
    name = ".config/zsh/${relative p}";
    value.source = p;
  }) files);
}
