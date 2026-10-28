{ ... }:
{
  # Ryzen 7 8845HS supports AMD P-State EPP. The active driver lets firmware
  # balance boost clocks against temperature and power limits.
  boot.kernelParams = [ "amd_pstate=active" ];

  powerManagement = {
    enable = true;
    # amd-pstate-epp uses the powersave governor with EPP policy hints.
    cpuFreqGovernor = "powersave";
  };

  # Let the Victus embedded controller manage the fans; use its platform
  # profile interface for the vendor's performance/thermal modes when exposed.
  services.upower.enable = true;
  services.tlp = {
    enable = true;
    # Expose the standard power-profiles D-Bus API for the Quickshell menu.
    pd.enable = true;
    settings = {
      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";

      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      # Favor efficiency for light work and keep firmware boost disabled on battery.
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "power";
      CPU_BOOST_ON_BAT = "0";

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
      PLATFORM_PROFILE_ON_SAV = "low-power";

      # Save power on idle PCIe, wireless, and audio devices while unplugged.
      RUNTIME_PM_ON_BAT = "auto";
      WIFI_PWR_ON_BAT = "on";
      SOUND_POWER_SAVE_ON_BAT = "1";
    };
  };
}
