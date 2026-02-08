{ config, pkgs, hostname, ... }: {
  # Mirach - Homelab server
  # Hardware: [describe hardware]
  # Role: Homelab (VMs, Docker services, Home Assistant)

  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos/services/icmp-ping-lan.nix # Allow ping from local network
    # Home Assistant service for homelab automation
    # ../../../modules/nixos/services/homeassistant.nix
  ];

  # Hostname
  networking.hostName = hostname;

  # Boot configuration
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking.networkmanager.enable = true;

  # User configuration
  users.users.djoolz = {
    isNormalUser = true;
    description = "djoolz";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "docker" ];
  };

  # Home-manager configuration for this machine
  # Uses desktop profile since we need GUI for management
  home-manager.users.djoolz = import ../../../flake/homes/profiles/desktop.nix;

  # Machine-specific packages
  environment.systemPackages = with pkgs;
    [
      # Add homelab-specific tools here
    ];

  system.stateVersion = "23.11";
}
