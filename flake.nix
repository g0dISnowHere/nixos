{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # Nixpkgs unstable for packages that need newer versions
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Use nixpkgs commit from previous working flake.lock
    nixpkgs-broken.url =
      "github:nixos/nixpkgs/ce01daebf8489ba97bd1609d185ea276efdeb121";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/";

    noctalia = {
      url =
        "github:noctalia-dev/noctalia-shell?rev=a1329203910dcd8ef97fb5e4049c8f59b34f6c59";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nirinit = {
      url = "github:amaanq/nirinit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixos-conf-editor.url = "github:snowfallorg/nixos-conf-editor";
    # nix-software-center.url = "github:snowfallorg/nix-software-center";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## encrypted key management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      # Keep sops-nix on the same nixpkgs revision as the rest of the flake.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    # ragenix = {
    #   url = "github:yaxitech/ragenix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    systems.url = "github:nix-systems/default";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    ## This looks promising. No idea how to make it work though.
    # lan-mouse.url = "github:feschber/lan-mouse";
  };

  outputs = { self, ... }@args: import ./outputs.nix args;
}
