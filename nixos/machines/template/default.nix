{ config, pkgs, lib, hostname, ... }:

{
  # Template machine configuration
  # Copy this directory and customize for new machines

  imports = [
    ./hardware-configuration.nix
    # ./bootloader.nix  # Uncomment if machine has custom bootloader config
    # ./networking.nix  # Uncomment if machine has custom networking config
  ];

  # Set the hostname
  networking.hostName = hostname;

  # Machine-specific configuration examples:

  # Example: Different timezone for different machines
  # time.timeZone = "America/New_York";

  # Example: Machine-specific services
  # services.xserver.videoDrivers = [ "nvidia" ];

  # Example: Machine-specific hardware
  # hardware.bluetooth.enable = true;

  # Example: Machine-specific users
  # users.users.otheruser = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ];
  # };
}
