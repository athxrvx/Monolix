{ config, pkgs, ... }:
{
  imports = [ ../power/lid-close.nix ];

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${config.programs.niri.package}/bin/niri-session";
      user = "greeter";
    };
  };

  # System integration for the compositor and greetd session; user settings
  # and autostart remain under Home Manager.
  programs.niri.enable = true;
  security.polkit.enable = true;
  programs.dconf.enable = true;
  programs.xwayland.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  fonts.packages = [
    pkgs.inter
  ];

  fonts.fontDir.enable = true;
}
