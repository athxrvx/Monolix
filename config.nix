{ pkgs, ... }:
let
  # Select one of the five system palettes below. Stylix applies this scheme
  # whenever the NixOS/Home Manager configuration is rebuilt.
  stylixScheme = "yoru";
  stylixSchemes = {
    jellybeans = ./home/home-manager/theme/jellybeans.yaml;
    aofuji = ./home/home-manager/theme/aofuji.yaml;
    nothing = ./home/home-manager/theme/nothing.yaml;
    oled = ./home/home-manager/theme/oled.yaml;
    yoru = ./home/home-manager/theme/yoru.yaml;
  };
in
{
  imports = [
    ./users/atharva.nix
    ./hosts/athena/athena.nix
  ];

  stylix = {
    enable = true;
    # Only generate app-specific theme files for explicitly enabled targets.
    autoEnable = false;
    polarity = if stylixScheme == "aofuji" then "light" else "dark";
    base16Scheme = stylixSchemes.${stylixScheme};

    fonts = {
      serif = { package = pkgs.inter; name = "Inter"; };
      sansSerif = { package = pkgs.inter; name = "Inter"; };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sizes = {
        applications = 11;
        terminal = 12;
        desktop = 10;
        popups = 11;
      };
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 20;
    };

    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus";
    };

    targets.gtk.enable = true;
    # Apply the active Stylix palette to Chromium's browser UI only.
    targets.chromium.enable = true;
    # Monolix owns the desktop settings UI; don't pull in qt5ct/qt6ct or
    # Kvantum just to expose a second theme control panel.
    targets.qt.enable = false;
  };
}
