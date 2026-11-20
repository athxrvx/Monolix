{ config, pkgs, ... }:
{
  imports = [ ../power/lid-close.nix ];

  # Reuse the LUKS/Plymouth boot password to unlock the GNOME keyring so the
  # autologin session starts already unlocked.
  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.greetd.text = ''
    auth substack login
    account include login
    password substack login

    session optional ${pkgs.pam_fde_boot_pw}/lib/security/pam_fde_boot_pw.so inject_for=gkr
    session include login
  '';

  services.greetd = {
    enable = true;
    settings.initial_session = {
      command = "${config.programs.hyprland.package}/bin/start-hyprland";
      user = "atharva";
    };
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${config.programs.hyprland.package}/bin/start-hyprland";
      user = "greeter";
    };
  };

  # System integration for the compositor and greetd session. The Kuro
  # Hyprland config, its autostart and generated appearance live in Home
  # Manager and ~/.config/kuro.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Runs as a systemd user service in the graphical session; reads
  # ~/.config/hypr/hypridle.conf, whose lock_cmd hands off to Quickshell.
  services.hypridle.enable = true;

  security.polkit.enable = true;
  programs.dconf.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.libinput.enable = true;

  fonts.packages = [
    pkgs.inter
  ];
  fonts.fontDir.enable = true;

  # Hyprland's portal should win for Wayland clients; GTK remains available
  # for xdg-desktop-portal consumers from the host configuration.
  xdg.portal.config.hyprland.default = [ "hyprland" "gtk" ];
}
