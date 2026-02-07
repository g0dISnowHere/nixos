{ config, lib, pkgs, ... }: {
  # Global Nix daemon configuration
  # Applies to all machines

  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    settings = {
      trusted-users = [ "djoolz" ];

      keep-outputs = false; # remove old derivations
      keep-derivations = false; # remove old derivations

      fallback = true;
      warn-dirty = false;
      auto-optimise-store = true;

      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://hetzner-cache.numtide.com"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;
}
