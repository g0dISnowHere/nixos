{ config, pkgs, pkgs-gnome48, ... }: {
  # GNOME Desktop Environment — Self-Contained
  # Imports shared desktop infrastructure from common.nix
  # Provides: GNOME DE + GDM, plus all dependencies from common.nix

  # Pin GNOME core to the last stable GNOME 48 packages.
  nixpkgs.overlays = [
    (final: prev: {
      gnome-shell = pkgs-gnome48.gnome-shell;
      mutter = pkgs-gnome48.mutter;
      gdm = pkgs-gnome48.gdm;
      gnome-session = pkgs-gnome48.gnome-session;
    })
  ];

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
  environment.systemPackages = with pkgs; [
    dconf2nix
    dconf-editor
    dconf
    gtop # for system-monitor-ng extension
  ];

  # GNOME-specific Flatpak applications
  services.flatpak.packages = [
    "org.gnome.Extensions" # GNOME Extensions Manager
    "org.gnome.PowerStats" # Power consumption monitor
  ];
}
