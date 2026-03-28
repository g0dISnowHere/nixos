{ config, pkgs, hostname, ... }: {
  # Mirach - Homelab server
  # Hardware: [describe hardware]
  # Role: Homelab (VMs, Docker services, Home Assistant)

  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos/system/my-options.nix # Custom 'my' namespace options
    ../../../modules/nixos/services/firewall.nix # Firewall with port rules
    ../../../modules/nixos/services/icmp-ping-lan.nix # Allow ping from local network

  ];

  # Hostname
  networking.hostName = hostname;

  # Libvirt bridge interface configuration
  my.libvirt = {
    bridgeInterface = "br0";
    physicalInterface = "enp0s31f6";
  };

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
  # Uses the user-specific desktop profile wrapper since we need GUI for management.
  home-manager.users.djoolz =
    import ../../../flake/homes/users/djoolz/desktop.nix;

  # Machine-specific packages
  environment.systemPackages = with pkgs;
    [
      # Add homelab-specific tools here
    ];

  system.stateVersion = "23.11";
}
