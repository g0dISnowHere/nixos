{ config, pkgs, pkgs-unstable, ... }: {
  # Desktop profile
  # Extends common profile with GUI applications and GNOME settings
  # Use this profile for workstations and GUI-enabled machines

  imports = [
    ./common.nix
    # Import dconf settings (GNOME configuration)
    ../../../modules/home/dconf/dconf.nix
  ];

  # Enable font configuration for GUI apps
  fonts.fontconfig.enable = true;

  # Desktop-specific packages
  # Most packages are already in common.nix via packages.nix import

  # Desktop-specific services
  services.syncthing.enable = true;

  # Desktop-specific program configurations
  # programs.firefox.enable = true;
  # ... etc ...
}
