{ config, lib, pkgs, ... }:
{
  # Workstation Role Profile
  # Interactive desktop machine for development and daily use
  #
  # Provides:
  # - Desktop environment (imported by machine)
  # - Audio/video support
  # - Networking with NetworkManager
  # - Printing and Bluetooth
  # - Power management for laptops

  imports = [
    # System essentials
    ../system/locale.nix
    ../system/shell.nix
    ../system/powermanagement.nix
    ../system/services.nix

    # Services
    ../services/tailscale.nix

    # Note: Desktop environment and virtualization are imported
    # by individual machines based on their needs
  ];

  # Networking
  networking.networkmanager.enable = true;

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
  };

  # Printing
  services.printing.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable CUPS for printer discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
