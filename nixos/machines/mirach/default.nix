{ config, pkgs, lib, hostname, ... }:

{
  imports = [
    # ./bootloader.nix
    ./configuration.nix
    ./hardware-configuration.nix
    # ./other-hardware.nix
    ../powermanagement.nix
    ../autoupgrade.nix
    # ./networking.nix
    # ./firewall.nix
  ];

  # Set the hostname
  networking.hostName = hostname;

  # Machine-specific configuration can go here
  # For example, if this machine has specific hardware requirements,
  # performance tuning, or other machine-specific settings

  # Example: Enable specific services only on this machine
  # services.some-service.enable = true;
}
