{ pkgs, ... }:
{
  imports = [
    ./core
  ];

  # Kuro owns themes, fonts and generated app colors through ~/.config/kuro.
  # Home Manager only installs static dotfiles and packages here.

  # Generate cursor links only in the XDG icon directory, not the legacy
  # ~/.icons compatibility directory. Stylix used to supply the cursor name;
  # set it explicitly now that theming is owned by Kuro.
  home.pointerCursor = {
    enable = true;
    dotIcons.enable = false;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 20;
    gtk.enable = true;
  };

  # If another package needs these Qt settings tools, keep them callable from
  # the terminal but out of the application launcher.
  xdg.desktopEntries.qt5ct = {
    name = "Qt5 Configuration Tool";
    exec = "qt5ct";
    type = "Application";
    categories = [ "Settings" ];
    noDisplay = true;
  };
  xdg.desktopEntries.qt6ct = {
    name = "Qt6 Configuration Tool";
    exec = "qt6ct";
    type = "Application";
    categories = [ "Settings" ];
    noDisplay = true;
  };

  # These tools remain available from the terminal, but their standalone
  # launchers are not part of the desktop workflow.
  xdg.desktopEntries.cups = {
    name = "Manage Printing";
    exec = "xdg-open http://localhost:631";
    type = "Application";
    noDisplay = true;
  };
  xdg.desktopEntries.system-config-printer = {
    name = "Manage Printing";
    exec = "system-config-printer";
    type = "Application";
    noDisplay = true;
  };
  xdg.desktopEntries.helix = {
    name = "Helix Editor";
    genericName = "Text Editor";
    exec = "kitty -e hx %F";
    type = "Application";
    categories = [ "Development" "TextEditor" ];
    terminal = false;
  };
  xdg.desktopEntries.ranger = {
    name = "ranger";
    exec = "kitty ranger";
    type = "Application";
    noDisplay = true;
  };

  programs.home-manager.enable = true;
}
