{ config, lib, pkgs, ... }: {
  # Homelab Role Profile
  # Server/homelab machine with optional GUI for management
  #
  # Provides:
  # - SSH server with secure defaults
  # - Tailscale for remote access
  # - Networking with NetworkManager
  # - Firewall enabled by default
  # - Optional desktop environment (imported by machine)
  #
  # Audio support (if needed) is provided by the desktop environment module when present

  imports = [
    # System essentials
    ../system/ai-tools.nix
    ../system/developer-tools.nix
    ../system/locale.nix
    ../system/nix-tools.nix
    ../system/shell.nix
    ../system/ssh-client.nix
    ../system/services.nix
    ../system/system-utils.nix

    # Services
    ../services/mosh.nix
    ../services/ssh.nix
    ../services/tailscale.nix
    ../services/vscode-remote.nix

    # Note: Desktop environment (for management), virtualization,
    # and machine-specific services are imported by the machine config
  ];

  # Networking
  networking.networkmanager.enable = lib.mkDefault true;
  networking.firewall.enable = true;

  my.tailscale = {
    enableSSH = true;
    advertiseExitNode = true;
  };
}
