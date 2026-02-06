{ config, lib, pkgs, pkgs-unstable, ... }:
{
  # Common home-manager configuration
  # Shared across all profiles - provides CLI essentials
  # Use this profile for headless servers

  imports = [
    # Import user modules
    ../../../modules/home/programs/programs.nix
    ../../../modules/home/packages/packages.nix
  ];

  # Basic home configuration
  # Note: Individual configs can override this
  home.stateVersion = lib.mkDefault "25.11";

  # Enable home-manager
  programs.home-manager.enable = true;

  # Basic CLI packages (minimal set - more in packages.nix)
  home.packages = with pkgs; [
    vim
    git
    htop
  ];
}
