{ ... }:

{
  networking = {
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };
    hostName = "athena";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  # tcp_bbr was loaded before but never selected.
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
}
