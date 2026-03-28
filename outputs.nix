{ self, home-manager, nixpkgs, flake-parts, nix-flatpak
, vscode-server, treefmt-nix, systems,
# nixpkgs-legacy,
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
    ./treefmt.nix
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
    # Define `nixosConfigurations` using our modular approach
    nixosConfigurations = import ./nixos/configurations.nix inputs;

    # System-agnostic flake attributes
    nixosModules = {
      # Export reusable modules for other flakes
      powermanagement = import ./nixos/machines/powermanagement.nix;
      autoupgrade = import ./nixos/machines/autoupgrade.nix;
    };

    # Optional: define homeConfigurations separately if needed
    # homeConfigurations = import ./home/configurations.nix inputs;
  };

  # See flake.parts for more features, such as `perSystem`
})
