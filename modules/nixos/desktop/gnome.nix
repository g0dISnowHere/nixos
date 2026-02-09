{ config, pkgs, ... }: {
  # GNOME Desktop Environment — Self-Contained
  # Imports shared desktop infrastructure from common.nix
  # Provides: GNOME DE + GDM, plus all dependencies from common.nix

  imports = [
    ./common.nix
    ./gsconnect.nix # Import self-contained GSConnect configuration with firewall rules
  ];

  # Enable GNOME Desktop Environment
  services.desktopManager.gnome.enable = true;

  # Enable GDM display manager (login screen)
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Enable dconf (GNOME settings backend)
  programs.dconf.enable = true;

  # GNOME-specific system packages
  environment.systemPackages = with pkgs; [ dconf2nix ];

  # GNOME-specific Flatpak applications
  services.flatpak.packages = [
    "org.gnome.Extensions" # GNOME Extensions Manager
    "org.gnome.PowerStats" # Power consumption monitor
  ];
}
