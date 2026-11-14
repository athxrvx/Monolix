{ pkgs, ... }:
let
  monolixPkg = import ./package.nix { inherit pkgs; };
in
{
  home.packages = [
    monolixPkg.monolix
    monolixPkg.quickshell
    pkgs.papirus-icon-theme
    pkgs.adwaita-icon-theme
    pkgs.adw-gtk3
    pkgs.glib
    pkgs.gsettings-desktop-schemas
    pkgs.inter
    pkgs.material-symbols
    pkgs.rubik
    pkgs.nerd-fonts.caskaydia-cove
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [ "Inter" ];
      monospace = [ "Iosevka Nerd Font" ];
    };
  };
}
