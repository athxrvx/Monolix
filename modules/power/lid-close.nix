{ pkgs, ... }:
let
  lidIsClosed = ''
    lid_is_closed() {
      local state
      for state in /proc/acpi/button/lid/*/state; do
        [ -r "$state" ] || continue
        ${pkgs.gnugrep}/bin/grep -qiE 'state:[[:space:]]*closed' "$state" && return 0
      done
      return 1
    }
  '';
in
{
  # ACPI handles lid close so Monolix is locked before the machine suspends.
  # Keep the ACPI lid device armed so opening the lid can wake the machine.
  services.udev.extraRules = ''
    SUBSYSTEM=="platform", KERNEL=="PNP0C0D:00", ATTR{power/wakeup}="enabled"
  '';

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  services.acpid = {
    enable = true;
    handlers.lid-close = {
      event = "button/lid.*";
      action = ''
        case "$1" in
          *close*) ${pkgs.systemd}/bin/systemctl start lid-close-suspend.service ;;
          *open*)
            ${pkgs.systemd}/bin/systemctl stop lid-close-suspend.service
            ;;
        esac
      '';
    };
  };

  systemd.services.lid-close-suspend = {
    description = "Lock Monolix and suspend when the laptop lid closes";
    serviceConfig.Type = "oneshot";
    script = ''
      ${lidIsClosed}
      lid_is_closed || exit 0

      ${pkgs.systemd}/bin/systemctl --user --machine=atharva@.host start monolix-lid-lock.service
      ${pkgs.coreutils}/bin/sleep 1

      # The lid may have been reopened while Monolix was locking.
      lid_is_closed && ${pkgs.systemd}/bin/systemctl suspend
    '';
  };
}
