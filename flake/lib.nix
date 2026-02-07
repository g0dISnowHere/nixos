{ inputs, ... }:
let
  inherit (inputs)
    nixpkgs home-manager nix-flatpak nixpkgs-unstable nixpkgs-tailscale;
in {
  flake.lib = {
    # Helper function to create a NixOS system configuration
    # Provides consistent setup for all machines with role-based defaults
    mkNixosSystem = { system, hostname, role, desktop ? null, modules ? [ ]
      , extraSpecialArgs ? { } }:
      let
        desktopModule = if desktop != null then
          ../modules/nixos/desktop/${desktop}.nix
        else
          { };
      in nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Machine-specific hardware and config
          ../nixos/machines/${hostname} # This is where the default.nix for centauri is imported

          # Role-based defaults (workstation, homelab, etc.)
          ../modules/nixos/roles/${role}.nix

          # Desktop environment (if specified)
          desktopModule

          # Home-manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              # Note: Individual machines set home-manager.users.*
              # in their default.nix to reference profile modules
              extraSpecialArgs = {
                pkgs-unstable = import nixpkgs-unstable {
                  inherit system;
                  config.allowUnfree = true;
                };
              };
            };
          }

          # Flatpak support
          nix-flatpak.nixosModules.nix-flatpak

          # Global Nix daemon settings
          ../modules/nixos/system/nix-settings.nix
          { nixpkgs.config.allowUnfree = true; }
        ] ++ modules;

        specialArgs = {
          inherit inputs hostname;
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-tailscale = import nixpkgs-tailscale {
            inherit system;
            config.allowUnfree = true;
          };
        } // extraSpecialArgs;
      };
  };
}
