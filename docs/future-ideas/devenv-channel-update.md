# Plan: Configure devenv to Use Unstable Channel Globally

## Analysis

The configuration can be made in `mine/nixos/home.nix` since that's where devenv is currently installed as part of the home.packages list.

## Current State

In `mine/nixos/home.nix`, devenv is simply listed as a package:
```nix
home.packages = with pkgs; [
  ...
  devenv
  ...
];
```

## Required Changes

We need to modify how devenv is imported to use the unstable channel. Looking at the flake.nix, we already have nixpkgs-unstable configured as an input:
```nix
nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
```

We can use this to specify that devenv should come from the unstable channel.

### Implementation Steps

1. Modify `mine/nixos/home.nix` to use pkgs-unstable for devenv specifically:
```nix
{ config, pkgs, pkgs-unstable, ... }:
{
  home.packages = with pkgs; [
    # other packages...
  ] ++ [
    pkgs-unstable.devenv  # Explicitly use devenv from unstable channel
  ];
}
```

2. Ensure the unstable packages are properly passed to home-manager in the NixOS configuration.

## Verification
After applying these changes and rebuilding your system:
1. Run `nix-env -qa devenv` to verify it's coming from the unstable channel
2. Check `devenv --version` to confirm you're getting the latest unstable version