{ config, pkgs, ... }:
{
  imports = [ ../power/lid-close.nix ];
  

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
      command = "${config.programs.niri.package}/bin/niri-session";
      user = "atharva";
    };    
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
