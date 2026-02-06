{ config, pkgs, pkgs-unstable, lib, ... }:

{
  # User-specific home-manager configuration
  # This imports the desktop profile which includes all GUI apps and settings
  # For machine-integrated home-manager (used by NixOS configurations)

  imports = [
    ../../flake/homes/profiles/desktop.nix
    # QuickEMU for easy VM management
    ../../modules/nixos/virtualisation/quickemu.nix
  ];

  # User identity
  home.username = "djoolz";
  home.homeDirectory = "/home/djoolz";

  # Keep state version aligned with system
  home.stateVersion = "24.11";
}
