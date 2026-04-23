{ self, home-manager, nixpkgs, nixpkgs-unstable, nixpkgs-broken, nixpkgs-zellij
, flake-parts, nix-flatpak, plasma-manager, treefmt-nix, systems,
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
    ./parts/devshells.nix
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

  perSystem = { ... }:
    {
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
