{ config, lib, pkgs, ... }:
let
  root = ./.;
  kurogen = import ../../kuro/kurogen.nix { inherit pkgs; };
  # QML hardcodes ~/.config/quickshell/shell, so install the tree there.
  # bin/kurogen is a generated wrapper added below, not a tracked file here.
  relative = p: lib.removePrefix (toString root + "/") (toString p);
  files = lib.filter
    (p: ! lib.hasSuffix "quickshell.nix" (toString p))
    (lib.filesystem.listFilesRecursive root);
in
{
  home.packages = with pkgs; [
    quickshell
    awww
    imagemagick
    pciutils
    # AI sidebar: YouTube search/playback and desktop application launching.
    yt-dlp
    dex
    # jq and python3 are already in core/development.nix.
    # mpv also serves the AI YouTube action; curl is used by AI tooling.
    mpv
    curl
    mpc
  ];

  services.mpd = {
    enable = true;
    musicDirectory = config.home.homeDirectory + "/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "Kuro MPD"
      }
      follow_outside_symlinks "yes"
      auto_update "yes"
    '';
  };

  # Make the same Home Manager-generated config available to `mpd` when it is
  # invoked directly; the systemd user service still uses this exact config.
  xdg.configFile."mpd/mpd.conf".text = config.services.mpd.generatedConfig;

  home.file = (lib.listToAttrs (map (p: {
    name = ".config/quickshell/shell/${relative p}";
    value.source = p;
  }) files)) // {
    # The path is hardcoded by Config.qml and the bin/skills/ai-* scripts.
    ".config/quickshell/shell/bin/kurogen".source = "${kurogen}/bin/kurogen";
  };

  # Called by the system lid-close handler before suspend.
  systemd.user.services.kuro-lid-lock = {
    Unit.Description = "Lock Kuro before lid-close suspend";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.quickshell}/bin/qs -c shell ipc call lock lock";
    };
  };
}
