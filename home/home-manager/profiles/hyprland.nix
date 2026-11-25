# Import-only wiring. Each config tree declares its own installation in the
# .nix file beside it; there is no central install module here.
{
  # Keep the PAM-unlocked daemon alive for the whole graphical session. Without
  # this, a later Secret Service request can D-Bus-activate a fresh locked daemon.
  services.gnome-keyring.enable = true;

  imports = [
    ../config/desktop/hyprland/hyprland.nix
    ../config/desktop/quickshell/kuro/quickshell.nix
    ../config/desktop/gtk/gtk.nix
    ../config/desktop/kuro/kuro.nix
    ../theme/colors/colors.nix
    ../theme/colors/theme-check.nix
    ../config/desktop/kitty/kitty.nix
    ../config/desktop/containers/containers.nix
    ../config/shell/zsh/kuro/kuro.nix
    ../config/apps/desktop-apps.nix
    ../config/services/easyeffects.nix
    ../config/services/kdeconnect.nix
  ];
}
