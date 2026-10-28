# Build Monolix from its Niri-adapted Caelestia source tree.
{ pkgs, ... }:
let
  lib = pkgs.lib;
  quickshell = pkgs.quickshell;
  optional = name: lib.optional (builtins.hasAttr name pkgs) (builtins.getAttr name pkgs);
  mpvWithMpris = pkgs.mpv.override {
    scripts = [ pkgs.mpvScripts.mpris ];
  };
  monolix = pkgs.callPackage ./monolix/nix/default.nix {
    rev = "monolix";
    inherit quickshell;
    extraRuntimeDeps =
      (optional "cliphist")
      ++ (optional "gpu-screen-recorder")
      ++ (optional "grim")
      ++ (optional "niri")
      ++ (optional "wireplumber")
      ++ (optional "playerctl")
      ++ (optional "mpc")
      ++ (optional "slurp")
      ++ (optional "tesseract")
      ++ (optional "libnotify")
      ++ [ mpvWithMpris ]
      ++ (optional "yt-dlp")
      ++ (optional "power-profiles-daemon")
      ++ (optional "systemd")
      ++ (optional "bluez")
      ++ (optional "xdg-utils")
      ++ (optional "curl")
      ++ (optional "matugen")
      ++ (optional "glib")
      ++ (optional "python3")
      ++ (optional "gsettings-desktop-schemas");
  };
  quickshellCommand = pkgs.writeShellScriptBin "quickshell" ''
    if [ "''${1-}" = "-c" ] && [ "''${2-}" = "monolix" ]; then
      shift 2
      exec ${monolix}/bin/monolix "$@"
    fi
    exec ${quickshell}/bin/qs "$@"
  '';
in {
  inherit monolix;
  quickshell = quickshellCommand;
}
