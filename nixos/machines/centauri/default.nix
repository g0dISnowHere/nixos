{ config, pkgs, hostname, ... }: {
  # Centauri - Primary laptop/workstation
  # Hardware: [describe hardware]
  # Role: Workstation (development, daily use)

  imports = [
    ./hardware-configuration.nix
    ./bootloader.nix
    ./other-hardware.nix
    ../../../modules/nixos/system/nix-settings.nix # Explicitly import nix-settings
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = hostname;

  # User configuration
  users.users.djoolz = {
    isNormalUser = true;
    description = "djoolz";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  # Home-manager configuration for this machine
  # References the desktop profile (GUI + dev tools)
  home-manager.users.djoolz = import ../../../flake/homes/profiles/desktop.nix;

  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # dconf settings (machine-specific overrides)
  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          # clock-show-weekday = true;
        };
      };
    }];
  };

  # Machine-specific packages
  environment.systemPackages = with pkgs;
    [
      # Add machine-specific tools here
    ];

  system.stateVersion = "25.11";
}
