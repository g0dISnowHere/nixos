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
    ../system/locale.nix
    ../system/login-shell.nix
    ../system/services.nix

    # Services
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
