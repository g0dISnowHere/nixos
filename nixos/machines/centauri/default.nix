{
  hostname,
  ...
}:
{
  # Centauri - Primary laptop
  # Hardware: [describe hardware]

  imports = [
    ./hardware-configuration.nix
    ./firewall.nix
    ./bootloader.nix
    ./bluetooth.nix
    ./graphics.nix
    ./input.nix
    ./printing.nix
    ../../../modules/nixos/system/autoupgrade.nix
    ../../../modules/nixos/system/base.nix
    ../../../modules/nixos/system/home-manager.nix
    ../../../modules/nixos/system/ai-tools.nix
    ../../../modules/nixos/system/developer-tools.nix
    ../../../modules/nixos/system/powermanagement.nix
    ../../../modules/nixos/system/gui-developer-tools.nix
    ../../../modules/nixos/services/audio.nix
    ../../../modules/nixos/services/firewall.nix # Firewall with port rules and bridge networking
    ../../../modules/nixos/services/fingerprint-06cb-009a.nix
    ../../../modules/nixos/services/monitoring-baseline.nix
    # ../../../modules/nixos/services/icmp-ping-lan.nix # Allow ping from local network
    ../../../modules/nixos/services/platformio.nix # USB serial and debugger udev access for PlatformIO
    ../../../modules/nixos/services/scanner.nix # SANE scanner support
    ../../../modules/nixos/services/flatpak.nix # Flatpak infrastructure
    ../../../modules/nixos/services/mosh.nix
    ../../../modules/nixos/services/tailscale-client.nix
    ../../../modules/nixos/services/avahi-discovery.nix
    ../../../modules/nixos/virtualisation/docker.nix
    ../../../modules/nixos/desktop/gnome.nix
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

  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  users.users.djoolz.extraGroups = [
    "networkmanager"
    "wheel"
    "docker"
    "scanner"
    "lp"
  ];

  home-manager.users.djoolz = {
    imports = [
      ../../../flake/homes/users/djoolz/base.nix
      ../../../flake/homes/users/djoolz/gui-apps.nix
    ];
    # Do not change casually. See docs/architecture/state-version-reasons.md.
    home.stateVersion = "25.11";
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # This laptop travels, so let NixOS track current local timezone.
  services.automatic-timezoned.enable = true;
  my.autoUpdate = {
    enable = true;
    mode = "consumer";
    onCalendar = "daily";
  };

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = "25.11";
}
