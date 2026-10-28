{ ... }:
{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "nixos_small";
        padding = { right = 1; };
      };
      display = {
        separator = "  ";
        color = {
          keys = "blue";
          title = "green";
        };
      };
      modules = [
        { type = "os"; key = "OS"; }
        { type = "kernel"; key = "Kernel"; }
        { type = "uptime"; key = "Uptime"; }
        { 
          type = "packages"; 
          key = "Packages"; 
          # Disable all package managers except Nix
          nix = true;
          pacman = false;
          flatpak = false;
          snap = false;
          brew = false;
          apk = false;
          apt = false;
          dnf = false;
          rpm = false;
          emerge = false;
          xbps = false;
          amdgpu = false; 
        }
        { type = "cpu"; key = "CPU"; }
        { 
          type = "gpu"; 
          key = "GPU"; 
          # Hides common integrated graphics names (Intel HD/Iris, AMD Radeon Graphics/Vega)
          hideType = "(integrated|intel.*graphics|intel.*iris|radeon.*graphics|amd.*vega)"; 
        }
        { type = "memory"; key = "RAM"; }
      ];
    };
  };
}
