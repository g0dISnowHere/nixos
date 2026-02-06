{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # Nixpkgs unstable for packages that need newer versions
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Use nixpkgs commit from previous working flake.lock
    nixpkgs-tailscale.url =
      "github:nixos/nixpkgs/ce01daebf8489ba97bd1609d185ea276efdeb121";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/";

    # nixos-conf-editor.url = "github:snowfallorg/nixos-conf-editor";
    # nix-software-center.url = "github:snowfallorg/nix-software-center";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## encrypted key management
    # sops-nix = {
    #   url = "github:Mic92/sops-nix";
    #   # `follows` is the inheritance syntax within inputs. Here, it ensures that sops-nix's `inputs.nixpkgs` aligns with the current flake's inputs.nixpkgs,# avoiding inconsistencies in the dependency's nixpkgs version.
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    flake-parts.url = "github:hercules-ci/flake-parts";

    systems.url = "github:nix-systems/default";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    ## This looks promising. No idea how to make it work though.
    # lan-mouse.url = "github:feschber/lan-mouse";
  };

  outputs = { self, ... }@args: import ./outputs.nix args;
}
