{ self, home-manager, nixpkgs, nixpkgs-unstable, nixpkgs-tailscale, flake-parts
, nix-flatpak, plasma-manager, treefmt-nix, systems,
# nixos-conf-editor,
# nix-software-center,
... }@inputs:

(flake-parts.lib.mkFlake { inherit inputs; } {

  imports = [
    # To import a flake module
    # 1. Add foo to inputs
    # 2. Add foo as a parameter to the outputs function
    # 3. Add here: foo.flakeModule

    # Import home-manager's flake module
    inputs.home-manager.flakeModules.home-manager
    inputs.treefmt-nix.flakeModule
    ./parts/formatter.nix

    # Library functions and machine definitions
    ./flake/lib.nix
    ./flake/machines/workstations.nix
    ./flake/machines/homelabs.nix

    # Standalone home-manager configurations
    ./flake/homes/djoolz.nix
  ];

  systems = [
    "x86_64-linux"
    "aarch64-linux"
    # "aarch64-darwin"
    # "x86_64-darwin"
  ];

  perSystem = { config, self', inputs', pkgs, lib, system, ... }: {
    # Per-system attributes can be defined here. The self' and inputs'
    # module parameters provide easy access to attributes of the same system.

    # Development shells for each system
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [ nixpkgs-fmt statix deadnix ];
      shellHook = ''
        echo "NixOS configuration development environment"
        echo "Current system: ${system}"
      '';
    };

    # System-specific packages could go here
    # packages.some-tool = pkgs.callPackage ./some-tool.nix {};
  };

  flake = {
    # `nixosConfigurations` are defined by importing flake/machines/*.nix
    # which use self.lib.mkNixosSystem with role-based defaults

    # System-agnostic flake attributes
    nixosModules = {
      # Export reusable modules for other flakes
      # TODO How to use this?
      # powermanagement = import ./modules/nixos/system/powermanagement.nix;
      # autoupgrade = import ./modules/nixos/system/autoupgrade.nix;
    };

    # Home-manager configurations are defined in flake/homes/*.nix
  };

  # See flake.parts for more features, such as `perSystem`
})
