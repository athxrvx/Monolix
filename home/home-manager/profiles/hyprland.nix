# Import-only wiring. Each config tree declares its own installation in the
# .nix file beside it; there is no central install module here.
{
  imports = [
    ../config/desktop/hyprland/hyprland.nix
    ../config/desktop/quickshell/kuro/quickshell.nix
    ../config/desktop/gtk/gtk.nix
    ../config/desktop/kuro/kuro.nix
    ../theme/colors/colors.nix
    ../config/desktop/kitty/kitty.nix
    ../config/desktop/containers/containers.nix
    ../config/shell/zsh/kuro/kuro.nix
    ../config/apps/desktop-apps.nix
    ../config/services/easyeffects.nix
    ../config/services/kdeconnect.nix
  ];
}
