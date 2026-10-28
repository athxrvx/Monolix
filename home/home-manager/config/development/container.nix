{ pkgs, ... }:

{
  programs.distrobox = {
    enable = true;
    package = pkgs.distrobox;

    enableSystemdUnit = true;

    settings = {
      container_manager = "podman";
      container_name_default = "dev";
      container_generate_entry = 1;
      container_always_pull = 0;
    };

    containers = {
      ubuntu = {
        image = "docker.io/library/ubuntu:24.04";

        additional_packages =
          "git curl wget ca-certificates build-essential "
          + "python3 python3-pip python3-venv "
          + "nodejs npm ripgrep fd-find jq tmux";

        root = false;
        replace = false;
        start_now = false;
      };

      fedora = {
        image = "registry.fedoraproject.org/fedora:latest";

        additional_packages =
          "git curl wget gcc gcc-c++ make "
          + "python3 python3-pip nodejs npm "
          + "ripgrep fd-find jq tmux";

        root = false;
        replace = false;
        start_now = false;
      };
    };
  };
}
