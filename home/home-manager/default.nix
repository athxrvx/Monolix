{ config, lib, pkgs, ... }:
let
  stylixScheme = import ./style.nix;
  stylixSchemes = {
    jellybeans = ./theme/jellybeans.yaml;
    aofuji = ./theme/aofuji.yaml;
    nothing = ./theme/nothing.yaml;
    oled = ./theme/oled.yaml;
    yoru = ./theme/yoru.yaml;
  };
  colors = config.lib.stylix.colors.withHashtag;
  gtk4Yoru = pkgs.writeText "gtk4-yoru-variables.css" ''
    window {
      --window-bg-color: ${colors.base00};
      --view-bg-color: ${colors.base00};
      --headerbar-bg-color: ${colors.base01};
      --headerbar-fg-color: ${colors.base05};
      --sidebar-bg-color: ${colors.base01};
      --sidebar-fg-color: ${colors.base05};
      --card-bg-color: ${colors.base02};
      --popover-bg-color: ${colors.base02};
      --popover-fg-color: ${colors.base05};
      --dialog-bg-color: ${colors.base01};
      --dialog-fg-color: ${colors.base05};
      --accent-color: ${colors.base0D};
      --accent-bg-color: ${colors.base0D};
      --accent-fg-color: ${colors.base00};
      --destructive-color: ${colors.base08};
      --destructive-bg-color: ${colors.base08};
      --success-color: ${colors.base0B};
      --success-bg-color: ${colors.base0B};
      --warning-color: ${colors.base09};
      --warning-bg-color: ${colors.base09};
    }
  '';
  gtk4Css = pkgs.runCommand "stylix-gtk4-theme" { } ''
    cat ${config.xdg.configFile."gtk-3.0/gtk.css".source} ${gtk4Yoru} > $out
  '';
in
{
  # The mono style command changes only this Home Manager palette; the
  # system-level Stylix palette remains a stable baseline.

  stylix.base16Scheme = stylixSchemes.${stylixScheme};
  stylix.polarity = if stylixScheme == "aofuji" then "light" else "dark";

  imports = [
    ./core
  ];
  stylix = {
    fonts = {
      sansSerif = {
        package = pkgs.inter;
        name = "Inter Display";
      };
    };
  };
  stylix.targets.qt.enable = false;
  stylix.targets.gtk.enable = true;
  stylix.targets.gtk.flatpakSupport.enable = true;
  stylix.targets.rofi.enable = false;
  xdg.configFile."gtk-4.0/gtk.css".source = lib.mkForce gtk4Css;

  # Generate cursor links only in the XDG icon directory, not the legacy
  # ~/.icons compatibility directory.
  home.pointerCursor.enable = true;
  home.pointerCursor.dotIcons.enable = false;

  # If another package needs these Qt settings tools, keep them callable from
  # the terminal but out of Monolix's application launcher.
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
  # launchers are not part of the Monolix desktop workflow.
  xdg.desktopEntries.emacsclient = {
    name = "Emacs (Client)";
    exec = "emacsclient -c";
    type = "Application";
    noDisplay = true;
  };
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
  xdg.desktopEntries.nvim = {
    name = "Neovim wrapper";
    exec = "monovim";
    type = "Application";
    noDisplay = true;
  };
  xdg.desktopEntries.neovim = {
    name = "Neovim wrapper";
    exec = "monovim";
    type = "Application";
    noDisplay = true;
  };
  xdg.desktopEntries.ranger = {
    name = "ranger";
    exec = "kitty ranger";
    type = "Application";
    noDisplay = true;
  };

  programs.home-manager.enable = true;

}
