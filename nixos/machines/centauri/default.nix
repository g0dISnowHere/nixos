{ pkgs, hostname, ... }: {
  # Centauri - Primary laptop/workstation
  # Hardware: [describe hardware]
  # Role: Workstation (development, daily use)

  imports = [
    ./hardware-configuration.nix
    ./firewall.nix
    ./bootloader.nix
    ./bluetooth.nix
    ./graphics.nix
    ./input.nix
    ./printing.nix
    ../../../modules/nixos/system/autoupgrade.nix
    ../../../modules/nixos/services/audio.nix
    ../../../modules/nixos/services/firewall.nix # Firewall with port rules and bridge networking
    ../../../modules/nixos/services/fingerprint-06cb-009a.nix
    ../../../modules/nixos/services/monitoring-baseline.nix
    # ../../../modules/nixos/services/icmp-ping-lan.nix # Allow ping from local network
    ../../../modules/nixos/services/platformio.nix # USB serial and debugger udev access for PlatformIO
    ../../../modules/nixos/services/scanner.nix # SANE scanner support
    ../../../modules/nixos/services/flatpak.nix # Flatpak infrastructure
    ../../../modules/nixos/flatpak/browsers.nix
    ../../../modules/nixos/flatpak/creative.nix
    ../../../modules/nixos/flatpak/development.nix
    ../../../modules/nixos/flatpak/media.nix
    ../../../modules/nixos/flatpak/messaging.nix
    ../../../modules/nixos/flatpak/productivity.nix
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
  # References the user-specific GUI profile wrapper.
  home-manager.users.djoolz = {
    imports = [ ../../../flake/homes/users/djoolz/workstation.nix ];
    # Do not change casually. See docs/architecture/state-version-reasons.md.
    home.stateVersion = "25.11";
  };

  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # This laptop travels, so let NixOS track the current local timezone.
  services.automatic-timezoned.enable = true;

  # Machine-specific packages
  environment.systemPackages = with pkgs;
    [
      # Add machine-specific tools here
    ];

  my.autoUpdate = {
    enable = true;
    mode = "consumer";
    onCalendar = "daily";
  };

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = "25.11";
}
