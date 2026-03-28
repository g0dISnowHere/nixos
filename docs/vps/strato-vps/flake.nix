{
  description = "NixOS flake for the current STRATO VPS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, disko, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
    in {
      nixosConfigurations.strato-vps = lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules =
          [ disko.nixosModules.disko ./hosts/strato-vps/configuration.nix ];
      };
    };
}
