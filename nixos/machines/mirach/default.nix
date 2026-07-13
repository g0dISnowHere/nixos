{
  pkgs,
  hostname,
  inputs,
  repoRoot,
  dotfilesRoot,
  pkgs-unstable,
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
    ../../../modules/nixos/services/zigbee2mqtt.nix
    # ../../../modules/nixos/services/audio.nix
    ../../../modules/nixos/services/firewall.nix # Firewall with port rules
    ../../../modules/nixos/services/icmp-ping-lan.nix # Allow ping from local network
    # ../../../modules/nixos/services/scanner.nix # SANE scanner support
    ../../../modules/nixos/services/flatpak.nix # Flatpak infrastructure
    ../../../modules/nixos/flatpak/browsers.nix
    ../../../modules/nixos/flatpak/development.nix
    ../../../modules/nixos/flatpak/productivity.nix
    ../../../modules/nixos/system/base.nix
    ../../../modules/nixos/system/ai-tools.nix
    ../../../modules/nixos/system/developer-tools.nix
    ../../../modules/nixos/desktop/gnome.nix
    ../../../modules/nixos/services/bluetooth.nix
    ../../../modules/nixos/services/printing.nix
    ../../../modules/nixos/services/avahi-discovery.nix
    ../../../modules/nixos/system/gui-developer-tools.nix
    ../../../modules/nixos/services/monitoring-baseline.nix
    ../../../modules/nixos/services/vscode-remote.nix
    ../../../modules/nixos/services/ssh-server.nix
    ../../../modules/nixos/services/tailscale-router.nix
    ../../../modules/nixos/virtualisation/docker.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  # Hostname
  networking.hostName = hostname;

  # Networking
  networking.networkmanager.enable = true;

  # Boot configuration
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

  # User configuration
  # Shared modules add service-specific groups like libvirtd and docker.
  users.users.djoolz.extraGroups = [
    "networkmanager"
    "wheel"
    "scanner"
    "lp"
    "docker"
  ];
  # Home-manager configuration for this machine
  # Match centauri's user environment and desktop applications.
  home-manager.users.djoolz = {
    imports = [
      ../../../flake/homes/users/djoolz/base.nix
      ../../../flake/homes/profiles/gui.nix
    ];
    # Do not change casually. See docs/architecture/state-version-reasons.md.
    home.stateVersion = "25.11";
  };

  # Home Manager integration settings
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
    extraSpecialArgs = {
      inherit
        dotfilesRoot
        inputs
        repoRoot
        pkgs-unstable
        ;
      isNixosIntegrated = true;
    };
    backupCommand = pkgs.writeShellScript "home-manager-backup" ''
      set -eu

      target_path="$1"
      backup_root="$HOME/.local/state/home-manager-backups"
      timestamp="$(date +%Y%m%d-%H%M%S-%N)"

      case "$target_path" in
        "$HOME"/*)
          relative_path="''${target_path#$HOME/}"
          ;;
        *)
          relative_path="external/$(basename "$target_path")"
          ;;
      esac

      backup_dir="$backup_root/$(dirname "$relative_path")"
      backup_name="$(basename "$target_path").$timestamp"
      backup_path="$backup_dir/$backup_name"

      mkdir -p "$backup_dir"
      mv "$target_path" "$backup_path"

      find "$backup_root" -type f -mtime +30 -delete
      find "$backup_root" -depth -type d -empty -delete
    '';
  };

  # Match centauri's AppImage support.
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
