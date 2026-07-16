{
  pkgs,
  hostname,
  ...
}:
{
  # Mirach - local virtualization and container host
  # Hardware: [describe hardware]

  imports = [
    ./hardware-configuration.nix
    ./firewall.nix
    ./libvirtd.nix
    ./power.nix
    ./ethernet-diagnostics.nix
    ../../../modules/nixos/system/autoupgrade.nix
    ../../../modules/nixos/system/base.nix
    ../../../modules/nixos/system/home-manager.nix
    ../../../modules/nixos/system/ai-tools.nix
    ../../../modules/nixos/system/developer-tools.nix
    ../../../modules/nixos/system/gui-developer-tools.nix
    ../../../modules/nixos/services/zigbee2mqtt.nix
    # ../../../modules/nixos/services/audio.nix
    ../../../modules/nixos/services/firewall.nix # Firewall with port rules
    ../../../modules/nixos/services/icmp-ping-lan.nix # Allow ping from local network
    # ../../../modules/nixos/services/scanner.nix # SANE scanner support
    ../../../modules/nixos/services/flatpak.nix # Flatpak infrastructure
    ../../../modules/nixos/services/bluetooth.nix
    ../../../modules/nixos/services/printing.nix
    ../../../modules/nixos/services/avahi-discovery.nix
    ../../../modules/nixos/services/monitoring-baseline.nix
    ../../../modules/nixos/services/vscode-remote.nix
    ../../../modules/nixos/services/ssh-server.nix
    ../../../modules/nixos/services/tailscale-router.nix
    ../../../modules/nixos/virtualisation/docker.nix
    ../../../modules/nixos/desktop/gnome.nix
    ../../../modules/nixos/flatpak/browsers.nix
    ../../../modules/nixos/flatpak/development.nix
    ../../../modules/nixos/flatpak/productivity.nix
  ];

  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = true;
      };
    };
  };
  boot.kernelPackages = pkgs.linuxPackages;
  hardware.firmware = [ pkgs.linux-firmware ];
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  # Shared modules add service-specific groups like libvirtd and docker.
  users.users.djoolz.extraGroups = [
    "networkmanager"
    "wheel"
    "scanner"
    "lp"
    "docker"
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

  my.tailscale = {
    enableSSH = true;
    advertiseExitNode = true;
    advertiseRoutes = [ "192.168.3.0/24" ];
  };

  my.autoUpdate = {
    enable = true;
    mode = "consumer";
    onCalendar = "daily";
    randomizedDelaySec = "90min";
  };

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = "25.11";
}
