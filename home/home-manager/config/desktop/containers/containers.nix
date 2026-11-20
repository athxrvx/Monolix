{ pkgs, ... }:

# Container tooling for the launcher's "Containers" section. No containers are
# declared here — create/manage them from the menu or the CLI. The launcher
# discovers running containers directly with `podman ps`, so it only needs the
# tools on PATH and distrobox pointed at podman.
{
  home.packages = with pkgs; [
    podman
    distrobox
  ];

  programs.distrobox = {
    enable = true;
    package = pkgs.distrobox;
    # No declarative containers, so no auto-build systemd unit. The launcher
    # creates and discovers containers imperatively with podman/distrobox.

    settings = {
      container_manager = "podman";
      container_name_default = "dev";
      container_generate_entry = 1;
      container_always_pull = 0;
    };
    # No `containers`: defined imperatively from the menu / CLI.
  };
}
