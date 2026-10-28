{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nautilus
    gnome-text-editor
    xdg-user-dirs
    hyprpaper
    ranger


    # User apps
    davinci-resolve
  ];

  services.flatpak = {
    enable = true;
    packages = [
        # "org.onlyoffice.desktopeditors"
        "org.libreoffice.LibreOffice"
        "com.obsproject.Studio"
        "com.usebottles.bottles"
        "info.febvre.Komikku"
        "org.vinegarhq.Sober"
    ];
    overrides.settings."org.onlyoffice.desktopeditors".Context.sockets = [ "x11" ];
  };
  stylix.targets.gtk.flatpakSupport.enable = true;

  programs.zathura = {
    enable = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
      "text/plain" = [ "org.gnome.TextEditor.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "text/html" = [ "chromium.desktop" "chromium-browser.desktop" ];
      "application/xhtml+xml" = [ "chromium.desktop" "chromium-browser.desktop" ];
      "x-scheme-handler/http" = [ "chromium.desktop" "chromium-browser.desktop" ];
      "x-scheme-handler/https" = [ "chromium.desktop" "chromium-browser.desktop" ];
      "x-scheme-handler/codex" = [ "chatgpt.desktop" ];
    };
  };

  # Keep GNOME apps dark and use the same Papirus icons as Monolix. Stylix
  # manages the GTK theme and palette through its Home Manager GTK target.
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    icon-theme = "Papirus-Dark";
  };
}
