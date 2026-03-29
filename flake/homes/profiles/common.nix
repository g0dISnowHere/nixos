{ config, lib, pkgs, pkgs-unstable, ... }: {
  # Common home-manager configuration
  # Shared across all profiles - provides CLI essentials
  # Use this profile for headless servers

  imports = [
    # Import user modules
    ../../../modules/home/programs/programs.nix
    ../../../modules/home/programs/developer-tools.nix
    ../../../modules/home/programs/ssh.nix
    ../../../modules/home/programs/shell.nix
    ../../../modules/home/packages/system-utils.nix
    ../../../modules/home/packages/nix-tools.nix
    ../../../modules/home/packages/ai-tools.nix
  ];
}
