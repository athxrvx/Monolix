{ pkgs, ... }:
{
  programs.zsh.enable = true;   # required for a zsh login shell

  # Password is the one set during installation (or change with `passwd`).
  users.users.atharva = {
    isNormalUser = true;
    description = "Atharva";
    extraGroups = [ "wheel" "networkmanager" "video" "kvm" ];
    shell = pkgs.zsh;
  };
}
