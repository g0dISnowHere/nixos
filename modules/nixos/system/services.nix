{ config, pkgs, ... }: {
  # System-wide services configuration
  # Note: Flatpak is now configured in modules/nixos/services/flatpak.nix

  # Require a password for sudo by default on all machines, including WSL.
  security.sudo.wheelNeedsPassword = true;
}
