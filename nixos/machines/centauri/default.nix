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
    ../../../modules/nixos/system/base.nix
    ../../../modules/nixos/system/ai-tools.nix
    ../../../modules/nixos/system/developer-tools.nix
    ../../../modules/nixos/system/powermanagement.nix
    ../../../modules/nixos/services/mosh.nix
    ../../../modules/nixos/services/tailscale-client.nix
    ../../../modules/nixos/services/avahi-discovery.nix
    ../../../modules/nixos/virtualisation/docker.nix
    ../../../modules/nixos/desktop/gnome.nix
    ../../../modules/nixos/system/gui-developer-tools.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = hostname;

  # Networking
  networking.networkmanager.enable = true;
  # User configuration
  users.users.djoolz.extraGroups = [
    "networkmanager"
    "wheel"
    "docker"
    "scanner"
    "lp"
  ];

  # Home-manager configuration for this machine
  # References the user-specific GUI profile wrapper.
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

  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # This laptop travels, so let NixOS track the current local timezone.
  services.automatic-timezoned.enable = true;

  # Machine-specific packages
  environment.systemPackages = with pkgs; [
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
