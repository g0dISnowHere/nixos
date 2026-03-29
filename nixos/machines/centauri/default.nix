{ config, pkgs, hostname, ... }: {
  # Centauri - Primary laptop/workstation
  # Hardware: [describe hardware]
  # Role: Workstation (development, daily use)

  imports = [
    ./hardware-configuration.nix
    ./bootloader.nix
    ./other-hardware.nix
    ../../../modules/nixos/services/audio.nix
    ../../../modules/nixos/services/firewall.nix # Firewall with port rules and bridge networking
    # ../../../modules/nixos/services/icmp-ping-lan.nix # Allow ping from local network
    ../../../modules/nixos/services/scanner.nix # SANE scanner support
    ../../../modules/nixos/services/flatpak.nix # Flatpak sandboxed apps
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = hostname;

  # User configuration
  users.users.djoolz.extraGroups =
    [ "networkmanager" "wheel" "docker" "scanner" "lp" ];

  # Home-manager configuration for this machine
  # References the user-specific desktop profile wrapper.
  home-manager.users.djoolz = {
    imports = [ ../../../flake/homes/users/djoolz/desktop.nix ];
    home.stateVersion = "24.11";
  };

  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Machine-specific packages
  environment.systemPackages = with pkgs;
    [
      # Add machine-specific tools here
    ];

  system.stateVersion = "25.11";
}
