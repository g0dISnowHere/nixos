{ hostname, pkgs, ... }: {
  # Mirach - Homelab server
  # Hardware: [describe hardware]
  # Role: Homelab (VMs, Docker services, Home Assistant)

  imports = [
    ./hardware-configuration.nix
    ./libvirtd.nix
    ../../../modules/nixos/services/vscode-remote.nix
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
  users.users.djoolz = {
    isNormalUser = true;
    description = "djoolz";
    # Shared modules add service-specific groups like libvirtd and docker.
    extraGroups = [ "networkmanager" "wheel" "scanner" "lp" ];
  };

  # Home-manager configuration for this machine
  # Match centauri's user environment and desktop applications.
  home-manager.users.djoolz =
    import ../../../flake/homes/users/djoolz/desktop.nix;

  # Match centauri's AppImage support.
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  my.tailscale.advertiseRoutes = [ "192.168.3.0/24" ];

  system.stateVersion = "25.05";
}
