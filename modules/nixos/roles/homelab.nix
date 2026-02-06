{ config, lib, pkgs, ... }:
{
  # Homelab Role Profile
  # Server/homelab machine with optional GUI for management
  #
  # Provides:
  # - SSH server with secure defaults
  # - Tailscale for remote access
  # - Networking with NetworkManager
  # - Firewall enabled by default
  # - Optional desktop environment (imported by machine)

  imports = [
    # System essentials
    ../system/locale.nix
    ../system/shell.nix
    ../system/services.nix

    # Services
    ../services/ssh.nix
    ../services/tailscale.nix

    # Note: Desktop environment (for management), virtualization,
    # and machine-specific services are imported by the machine config
  ];

  # Networking
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # SSH with secure defaults
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Optional: Audio for machines with GUI
  # Enabled by default, can be disabled in machine config
  security.rtkit.enable = lib.mkDefault true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };
}
