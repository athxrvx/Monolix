{ pkgs, ... }:
{
  home.packages = with pkgs; [
    xdg-user-dirs
    ranger
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
      "text/plain" = [ "nvim.desktop" ];
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
