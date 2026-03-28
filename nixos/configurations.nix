{ self, nixpkgs, home-manager, nix-flatpak, vscode-server, ... }@inputs:

let
  # Helper function to create a NixOS system configuration
  mkNixosSystem = { system, hostname, modules ? [ ], extraSpecialArgs ? { } }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        # Base configuration that all machines inherit
        # ./configuration.nix

        # Machine-specific configuration
        ./machines/${hostname}

        # Home-manager integration
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.djoolz = import ./users/djoolz.nix;
            extraSpecialArgs = extraSpecialArgs;
          };
        }

        # Flatpak support
        nix-flatpak.nixosModules.nix-flatpak

        # Global Nix configuration
        {
          nix = {
            extraOptions = "experimental-features = nix-command flakes";
            settings = {
              trusted-users = [ "djoolz" ];
              extra-substituters = [ "https://nix-community.cachix.org" ];
              extra-trusted-public-keys = [
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
            };
          };
        }
      ] ++ modules;

      specialArgs = {
        inherit inputs;
        hostname = hostname;
      } // extraSpecialArgs;
    };
in {
  # Desktop machines
  centauri = mkNixosSystem {
    system = "x86_64-linux";
    hostname = "centauri";
    modules = [ ];
  };

  mirach = mkNixosSystem {
    system = "x86_64-linux";
    hostname = "mirach";
    modules = [
      vscode-server.nixosModules.default
      ({ config, pkgs, ... }: { services.vscode-server.enable = true; })
    ];
  };

  # Add more machines as needed
  # Example for a different architecture:
  # rpi4 = mkNixosSystem {
  #   system = "aarch64-linux";
  #   hostname = "rpi4";
  #   modules = [
  #     # Raspberry Pi specific modules
  #   ];
  # };
}
