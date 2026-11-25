{ pkgs, ... }:
let
  thunarImageActions = pkgs.writeShellApplication {
    name = "thunar-image";
    runtimeInputs = [ pkgs.imagemagick pkgs.zenity pkgs.coreutils pkgs.jq ];
    text = builtins.readFile ./thunar/image-actions.sh;
  };
  thunarFileActions = pkgs.writeShellApplication {
    name = "thunar-file";
    runtimeInputs = [ pkgs.coreutils pkgs.zip pkgs.unzip pkgs.gnutar pkgs.xz pkgs.wl-clipboard pkgs.zenity ];
    text = builtins.readFile ./thunar/file-actions.sh;
  };
in
{
  home.packages = [
    pkgs.xdg-user-dirs
    pkgs.ranger
    thunarImageActions
    thunarFileActions
  ];

  services.flatpak = {
    enable = true;
    packages = [
        "com.obsproject.Studio"
        "com.usebottles.bottles"
    ];
  };
  programs.zathura = {
    enable = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "text/plain" = [ "helix.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "application/xhtml+xml" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/codex" = [ "chatgpt.desktop" ];
    };
  };

  xdg.configFile."Thunar/uca.xml".source = ./thunar/uca.xml;

  # GTK/GNOME appearance is declared in ../desktop/gtk/gtk.nix alongside the
  # static GTK settings and the Orchis theme.
}
