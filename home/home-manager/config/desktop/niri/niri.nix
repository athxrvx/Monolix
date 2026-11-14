{ config, pkgs, ... }:
let
  monolix = (import ../quickshell/package.nix { inherit pkgs; }).monolix;
  startMonolix = pkgs.writeShellScript "start-monolix-from-niri" ''
    # Niri owns the live Wayland session environment. Import it before asking
    # the user service manager to start Monolix, so the service sees the same
    # compositor socket and session variables as a manual launch from Niri.
    ${pkgs.systemd}/bin/systemctl --user import-environment \
      WAYLAND_DISPLAY DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP NIRI_SOCKET
    ${pkgs.systemd}/bin/systemctl --user start monolix.service
  '';
  colors = config.lib.stylix.colors.withHashtag;
  source = builtins.readFile ./config.kdl;
  niriConfig = builtins.replaceStrings
    [ "@STYLIX_ACTIVE@" "@STYLIX_INACTIVE@" "@STYLIX_BACKGROUND@" "@MONOLIX@" "@MONOLIX_START@" "@KITTY@" "@WPCTL@" "@PLAYERCTL@" "@BRIGHTNESSCTL@" "@NIRI@" ]
    [ colors.base0D colors.base02 colors.base00 "${monolix}/bin/monolix" "${startMonolix}/bin/start-monolix-from-niri" "${pkgs.kitty}/bin/kitty" "${pkgs.wireplumber}/bin/wpctl" "${pkgs.playerctl}/bin/playerctl" "${pkgs.brightnessctl}/bin/brightnessctl" "${pkgs.niri}/bin/niri" ]
    source;
in
{
  xdg.configFile."niri/config.kdl".text = niriConfig;
}
