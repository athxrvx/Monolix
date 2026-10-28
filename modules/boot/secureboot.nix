{ config, lib, pkgs, ... }:
let
  cfg = config.athena.secureboot;
in
{
  options.athena.secureboot.enable =
    lib.mkEnableOption "Lanzaboote signed boot entries (Secure Boot)";

  config = lib.mkMerge [
    # sbctl is always available so keys can be created before enabling.
    { environment.systemPackages = [ pkgs.sbctl ]; }

    (lib.mkIf cfg.enable {
      # Lanzaboote replaces systemd-boot with signed UKIs.
      boot.loader.systemd-boot.enable = lib.mkForce false;
      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };
    })
  ];
}
