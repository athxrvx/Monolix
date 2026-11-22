{
  description = "Kuro NixOS";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.8.0";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, lanzaboote, nix-flatpak, ... }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      athena = lib.nixosSystem {
        inherit system;
        modules = [
          ./config.nix
          home-manager.nixosModules.home-manager
          lanzaboote.nixosModules.lanzaboote
          ./modules/boot/secureboot.nix
          ./modules/desktop/hyprland.nix
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Preserve existing user files when Home Manager first takes
            # ownership of them (including the current mimeapps.list).
            home-manager.backupFileExtension = "backup";
            home-manager.users.atharva = {
              imports = [
                ./home/home-manager
                ./home/home-manager/profiles/hyprland.nix
                nix-flatpak.homeManagerModules.nix-flatpak
              ];
              home.stateVersion = "26.05";
            };
          }
        ];
      };
    };
  };
}
