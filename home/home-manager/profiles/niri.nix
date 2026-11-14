{ pkgs, ... }:
let
  monolix = (import ../config/desktop/quickshell/package.nix { inherit pkgs; }).monolix;
  idleLockAndScreenOff = pkgs.writeShellScript "monolix-idle-lock-screen-off" ''
    set -eu
    ${monolix}/bin/monolix ipc call lock lock
    ${pkgs.niri}/bin/niri msg action power-off-monitors
  '';
in
{
  imports = [
    ../config/desktop/niri/niri.nix
    ../config/desktop/quickshell/quickshell.nix
    ../config/desktop/kitty/kitty.nix
    ../config/apps/desktop-apps.nix
    ../config/services/kdeconnect.nix
    ../config/services/easyeffects.nix
  ];

  home.packages = with pkgs; [
    xwayland-satellite          # niri spawns this for X11 apps
    nerd-fonts.jetbrains-mono
  ];

  # Start Monolix with Niri's graphical session and restart it if it exits.
  # Keeping this in systemd also makes startup ordering consistent with the
  # Wayland session environment imported by niri-session.
  systemd.user.services.monolix = {
    Unit = {
      Description = "Monolix desktop shell";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${monolix}/bin/monolix";
      # Monolix starts user applications; stopping the shell must not kill
      # those applications with the shell's service cgroup.
      KillMode = "process";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Called by the system ACPI handler so the running shell is locked before
  # the machine suspends on lid close.
  systemd.user.services.monolix-lid-lock = {
    Unit.Description = "Lock Monolix before lid-close suspend";
    Service = {
      Type = "oneshot";
      ExecStart = "${monolix}/bin/monolix ipc call lock lock";
    };
  };

  # GNOME-style idle behavior: lock the session and turn off displays after
  # five minutes. The lid-close path handles suspend separately; lock again
  # before any other sleep request, such as the power button.
  systemd.user.services.monolix-idle = {
    Unit = {
      Description = "Lock and turn off displays while idle";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "monolix.service" ];
    };
    Service = {
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 300 '${idleLockAndScreenOff}' before-sleep '${monolix}/bin/monolix ipc call lock lock'";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.sessionVariables = {
    TERMINAL = "kitty";
    NIXOS_OZONE_WL = "1";       # native Wayland for Chromium/Electron
  };
}
