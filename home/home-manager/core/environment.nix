{ config, ... }:
{
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    SUDO_EDITOR = "hx";
    GIT_EDITOR = "hx";
    GIT_SEQUENCE_EDITOR = "hx";
    NIX_EDITOR = "hx";
    # The flake lives at ~/.config/nixconfig. Set it explicitly so the kuro
    # CLI and the launcher's update entries work from any directory.
    KURO_FLAKE = "${config.home.homeDirectory}/.config/nixconfig";
    KURO_PROFILE = "athena";
    KURO_USER = "atharva";
  };
}
