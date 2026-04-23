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
    ./parts/templates.nix

    # Library functions and machine definitions
    ./flake/lib.nix
    ./flake/machines/workstations.nix
    ./flake/machines/servers.nix

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
    # which use self.lib.mkNixosSystem plus explicit capability modules.

    # Reusable NixOS capability modules for this or other flakes.
    nixosModules = {
      system-base = ./modules/nixos/system/base.nix;
      system-wsl = ./modules/nixos/system/wsl.nix;
      ssh-server = ./modules/nixos/services/ssh-server.nix;
      tailscale-client = ./modules/nixos/services/tailscale-client.nix;
      tailscale-router = ./modules/nixos/services/tailscale-router.nix;
      flatpak = ./modules/nixos/services/flatpak.nix;
      flatpak-browsers = ./modules/nixos/flatpak/browsers.nix;
      flatpak-creative = ./modules/nixos/flatpak/creative.nix;
      flatpak-development = ./modules/nixos/flatpak/development.nix;
      flatpak-media = ./modules/nixos/flatpak/media.nix;
      flatpak-messaging = ./modules/nixos/flatpak/messaging.nix;
      flatpak-productivity = ./modules/nixos/flatpak/productivity.nix;
      docker = ./modules/nixos/virtualisation/docker.nix;
      docker-rootless = ./modules/nixos/virtualisation/docker_rootless.nix;
    };

    # Home-manager configurations are defined in flake/homes/*.nix
  };

  # See flake.parts for more features, such as `perSystem`
})
