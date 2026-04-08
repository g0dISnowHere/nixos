{ hostname, pkgs, ... }: {
  # Mirach - Homelab server
  # Hardware: [describe hardware]
  # Role: Homelab (VMs, Docker services, Home Assistant)

  imports = [
    ./hardware-configuration.nix
    ./libvirtd.nix
    ./power.nix
    ../../../modules/nixos/system/autoupgrade.nix
    ../../../modules/nixos/services/zigbee2mqtt.nix
    # ../../../modules/nixos/services/audio.nix
    ../../../modules/nixos/services/firewall.nix # Firewall with port rules
    ../../../modules/nixos/services/icmp-ping-lan.nix # Allow ping from local network
    # ../../../modules/nixos/services/scanner.nix # SANE scanner support
    ../../../modules/nixos/services/flatpak.nix # Flatpak sandboxed apps
  ];

  # Hostname
  networking.hostName = hostname;

  # Boot configuration
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.firmware = [ pkgs.linux-firmware ];
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 16 * 1024;
  }];

  # User configuration
  # Shared modules add service-specific groups like libvirtd and docker.
  users.users.djoolz.extraGroups = [ "networkmanager" "wheel" "scanner" "lp" ];

  # Home-manager configuration for this machine
  # Match centauri's user environment and desktop applications.
  home-manager.users.djoolz = {
    imports = [ ../../../flake/homes/users/djoolz/workstation.nix ];
    # Do not change casually. See docs/architecture/state-version-reasons.md.
    home.stateVersion = "25.11";
  };

  # Match centauri's AppImage support.
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  my.tailscale.advertiseRoutes = [ "192.168.3.0/24" ];

  my.autoUpdate = {
    enable = true;
    mode = "consumer";
    onCalendar = "daily";
    randomizedDelaySec = "90min";
  };

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = "25.11";
}
