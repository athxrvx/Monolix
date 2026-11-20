{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nautilus
    gnome-text-editor
    xdg-user-dirs
    ranger
    discord
    
    zoxide
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
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
      "text/plain" = [ "org.gnome.TextEditor.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "application/xhtml+xml" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];q
      "x-scheme-handler/codex" = [ "chatgpt.desktop" ];
    };
  };

  # GTK/GNOME appearance is declared in ../desktop/gtk/gtk.nix alongside the
  # static GTK settings and the Orchis theme.
}
