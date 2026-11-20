{ lib, pkgs, ... }:
let
  root = ./.;
  orchis = ../../../theme/Orchis-Dark;
in
{
  home.packages = with pkgs; [
    papirus-icon-theme
    fira-sans
    inter
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    nerd-fonts.caskaydia-cove
    nerd-fonts.fira-code
  ];

  home.file = {
    ".config/gtk-2.0/gtkrc".source = "${root}/gtkrc-2.0";
    ".config/gtk-3.0/settings.ini".source = "${root}/settings-gtk3.ini";
    ".config/gtk-4.0/settings.ini".source = "${root}/settings-gtk4.ini";
    ".config/xsettingsd/xsettingsd.conf".source = "${root}/xsettingsd.conf";
    ".local/share/themes/Orchis-Dark".source = orchis;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Orchis-Dark";
    icon-theme = "Papirus-Dark";
    font-name = "Fira Sans 11";
  };
}
