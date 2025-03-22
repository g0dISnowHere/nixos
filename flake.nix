{
  description = "My nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    # Nixpkgs unstable TODO use this for vscode.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.follows = "nixpkgs";

    # # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    ...
  } @ inputs: 
  let
    inherit (self) outputs;
  in {
    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      # FIXME replace with your hostname
      mirach = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          # The main nixos configuration file.
          ./configuration.nix

          # Add a cache server to hopefully make updating way faster.
          # https://nixos-and-flakes.thiscute.world/nix-store/add-binary-cache-servers
          {
            nix.settings = {
              trusted-users = ["djoolz"];
              substituters = [
                "https://cache.nixos.org/" # This seems to be the always active default.
                "https://nix-community.cachix.org" 
              ];
              trusted-public-keys = [
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
              ## When would I need an extra-substituter?
              # extra-substituters = [
              #   "https://nix-community.cachix.org" 
              # ];
              # extra-trusted-public-keys = [
              #   "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              # ];
            };
          }

          # home manager configuration
          home-manager.nixosModules.home-manager
          {
            # home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Optionally, use home-manager.extraSpecialArgs to pass arguments to home.nix
            home-manager.extraSpecialArgs = {inherit inputs outputs;};
            home-manager.users.djoolz = import ./home-manager/home.nix;
          }
        ];
      };
    };
  };
}
