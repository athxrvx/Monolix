{ lib, pkgs, ... }:
let
  root = ./.;
  kurogen = import ../../kuro/kurogen.nix { inherit pkgs; };
  # QML hardcodes ~/.config/quickshell/shell, so install the tree there.
  # bin/kurogen is a generated wrapper added below, not a tracked file here.
  files = lib.filter
    (p: ! lib.hasSuffix "quickshell.nix" (toString p))
    (lib.filesystem.listFilesRecursive root);
  relative = p: lib.removePrefix (toString root + "/") (toString p);
in
{
  home.packages = with pkgs; [
    quickshell
    awww
    jq
    python3
    # Anime sidebar: vendored ani-cli is installed by home.file below; these
    # are its runtime deps (player, HTTP client, and the `script` pty helper
    # that lets ani-cli's fzf-style menu render inside the shell).
    mpv
    curl
    util-linux
  ];

  home.file = (lib.listToAttrs (map (p: {
    name = ".config/quickshell/shell/${relative p}";
    value.source = p;
  }) files)) // {
    # The path is hardcoded by Config.qml and the bin/ai-* scripts.
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
