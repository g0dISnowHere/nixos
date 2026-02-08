{ config, pkgs, ... }: {
  # KDE Plasma Desktop Environment — Self-Contained
  # Imports shared desktop infrastructure from common.nix
  # Provides: Plasma 6 DE + SDDM, plus all dependencies from common.nix
  # Reference: https://wiki.nixos.org/wiki/KDE

  imports = [ ./common.nix ];

  # Enable Plasma 6 Desktop Environment
  services.desktopManager.plasma6.enable = true;

  # Enable SDDM display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
}
