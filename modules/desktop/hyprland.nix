{ config, pkgs, lib, ... }:
{
  imports = [ ../power/lid-close.nix ];

  # ============================================================
  # GNOME KEYRING
  # ============================================================

  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # SDDM autologin PAM configuration:
  # Must include pam_permit.so, account, and session so autologin succeeds without password,
  # while attempting to load cached LUKS passphrase via pam_systemd_loadkey into gnome-keyring.
  security.pam.services.sddm-autologin = {
    enableGnomeKeyring = true;
    text = lib.mkForce ''
      auth requisite pam_nologin.so
      auth optional ${config.systemd.package}/lib/security/pam_systemd_loadkey.so
      auth optional ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so
      auth required pam_succeed_if.so uid >= 1000 quiet
      auth required pam_permit.so

      account include sddm
      password include sddm
      session include sddm
      session optional ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
    '';
  };

  systemd.services.display-manager.serviceConfig.KeyringMode = "inherit";

  # ========================================    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;====================
  # SDDM DISPLAY MANAGER
  # ============================================================

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      settings = {
        Autologin = {
          Session = "hyprland.desktop";
          User = "atharva";
        };
      };
    };

    autoLogin = {
      enable = true;
      user = "atharva";
    };

    defaultSession = "hyprland";
  };

  # ============================================================
  # HYPRLAND
  # ============================================================

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Runs as a systemd user service in the graphical session; reads ~/.config/hypr/hypridle.conf
  services.hypridle.enable = true;

  # ============================================================
  # SYSTEM INTEGRATION
  # ============================================================

  security.polkit.enable = true;
  programs.dconf.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.libinput.enable = true;

  # Thunar, with persistent Xfconf settings, archive/media/VCS extensions,
  # and thumbnail support for video, PDF, and WebP files.
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
      thunar-vcs-plugin
    ];
  };
  programs.xfconf.enable = true;
  services.tumbler.enable = true;
  programs.gdk-pixbuf.modulePackages = [ pkgs.webp-pixbuf-loader ];
  environment.systemPackages = with pkgs; [
    file-roller
    ffmpegthumbnailer
    poppler
    android-tools
  ];

  # ============================================================
  # FONTS
  # ============================================================

  fonts.packages = [
    pkgs.inter
    pkgs.fira-sans
  ];
  fonts.fontDir.enable = true;

  # ============================================================
  # XDG DESKTOP PORTALS
  # ============================================================

  xdg.portal.config.hyprland.default = [
    "hyprland"
    "gtk"
  ];
}
