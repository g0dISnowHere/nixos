{ config, lib, pkgs, ... }: {
  # Workstation Role Profile
  # Interactive desktop machine for development and daily use
  #
  # Provides:
  # - Desktop environment (imported by machine)
  # - Networking with NetworkManager
  # - Power management for laptops
  #
  # Audio, printing, and Bluetooth are provided by the desktop environment module

  imports = [
    # System essentials
    ../system/locale.nix
    ../system/login-shell.nix
    ../system/powermanagement.nix
    ../system/services.nix

    # Services
    ../services/tailscale.nix

    # Note: Desktop environment (and its dependencies like audio, printing, bluetooth)
    # are imported by individual machines based on their needs
  ];

  # Networking
  networking.networkmanager.enable = true;
}
