{ ... }:
{
  services.resolved = {
    enable = true;
    settings.Resolve.DNSSEC = "allow-downgrade";   # strict "true" breaks on many ISP resolvers
  };
  services.earlyoom.enable = true;
  services.fstrim.enable = true;   # weekly NVMe TRIM
  services.fwupd.enable = true;    # firmware/BIOS updates
  zramSwap.enable = true;

  # Battery/power info for Monolix and apps (Quickshell.Services.UPower).
  services.upower.enable = true;

  # Monolix screen recording (KMS capture needs the capability wrapper).
  programs.gpu-screen-recorder.enable = true;
}
