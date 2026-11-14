{
  description = "NixOS Incandescent";

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
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    boba = {
      url = "github:athxrvx/boba/0e519ae673c760ca9f278d8690367c3a4be1c732";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, lanzaboote, stylix, nix-flatpak, ... }@inputs:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    mkAthena = { desktopModule, homeProfile }:
      lib.nixosSystem {
        inherit system;
        modules = [
          ./config.nix
          home-manager.nixosModules.home-manager
          lanzaboote.nixosModules.lanzaboote
          stylix.nixosModules.stylix
          ./modules/boot/secureboot.nix
          desktopModule
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Preserve existing user files when Home Manager first takes
            # ownership of them (including the current mimeapps.list).
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit (inputs) boba; };
            home-manager.users.atharva = {
              imports = [
                ./home/home-manager
                homeProfile
                nix-flatpak.homeManagerModules.nix-flatpak
              ];
              home.stateVersion = "26.05";
            };
          }
        ];
      };
  in {
    nixosConfigurations = {
      athena = mkAthena {
        desktopModule = ./modules/desktop/niri.nix;
        homeProfile = ./home/home-manager/profiles/niri.nix;
      };
      athena-xmonad = mkAthena {
        desktopModule = ./modules/desktop/xmonad.nix;
        homeProfile = ./home/home-manager/profiles/xmonad.nix;
      };
    };
  };
}
