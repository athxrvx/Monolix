{ ... }:
{
  # Ryzen 7 8845HS supports AMD P-State EPP. Let the active driver balance
  # boost clocks against temperature and power limits; TuneD owns the policy.
  boot.kernelParams = [ "amd_pstate=active" ];

  # Kernel sleep/hibernate and UPower are infrastructure, not competing
  # governors. UPower is also required by tuned-ppd for battery detection.
  powerManagement.enable = true;
  services.upower.enable = true;

  # Single power authority: TuneD plus its power-profiles-daemon compatibility
  # service (tuned-ppd). The Kuro shell's power page keeps calling
  # powerprofilesctl, which now talks to tuned-ppd over the PPD D-Bus API.
  # ppdSettings is the only place that selects a profile; `recommend` is
  # intentionally left unset so it cannot become a second authority.
  services.tuned = {
    enable = true;
    ppdSupport = true;
    ppdSettings.main.default = "balanced";
  };

  # Explicitly keep out every other CPU/power-policy daemon. NixOS's tuned
  # module asserts against these anyway; stating it here makes the intent
  # obvious and guards against a desktop module enabling one by default.
  services.power-profiles-daemon.enable = false;
  services.auto-cpufreq.enable = false;
  services.tlp.enable = false;
  hardware.system76.power-daemon.enable = false;
}
