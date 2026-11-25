{ pkgs, lib, ... }:
{
  services.resolved = {
    enable = true;
    settings.Resolve.DNSSEC = "allow-downgrade"; # strict "true" breaks on many ISP resolvers
  };
  services.earlyoom.enable = true;
  services.fstrim.enable = true; # weekly NVMe TRIM
  services.fwupd.enable = true; # firmware/BIOS updates
  zramSwap.enable = true;

  services.portmaster.enable = true;
  # Battery/power info for Kuro and apps (Quickshell.Services.UPower).
  services.upower.enable = true;

  # Kuro screen recording (KMS capture needs the capability wrapper).
  programs.gpu-screen-recorder.enable = true;

  # Local LLM server. Use the CUDA build so Ollama runs on the RTX 4050
  # instead of the iGPU. athena is a PRIME offload laptop, so point the
  # service at the discrete NVIDIA GPU explicitly. The NixOS module already
  # opens the nvidia device nodes in its sandbox and sets PrivateDevices=false.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    environmentVariables = {
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      CUDA_VISIBLE_DEVICES = "0";
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # Keep the Ollama unit available for the shell's explicit Start/Stop switch,
  # but leave it stopped at boot so CUDA does not wake the discrete GPU.
  systemd.services.ollama.wantedBy = lib.mkForce [ ];

  # Let the logged-in desktop user control only the Ollama unit through the
  # sidebar. No other privileged systemd service actions are granted here.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user === "atharva" &&
          action.id === "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") === "ollama.service" &&
          ["start", "stop"].indexOf(action.lookup("verb")) !== -1) {
        return polkit.Result.YES;
      }
    });
  '';
}
