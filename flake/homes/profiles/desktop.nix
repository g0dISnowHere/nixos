{ config, pkgs, pkgs-unstable, inputs, desktop ? null, ... }: {
  # Desktop profile
  # Extends common profile with GUI applications and DE-specific settings
  # Use this profile for workstations and GUI-enabled machines
  # DE-specific settings are conditionally imported based on the active desktop environment

  imports = [
    ./common.nix
    # GNOME: dconf settings
    # Uncomment below to enable GNOME home-manager config when desktop = "gnome"
    # ../../../modules/home/dconf/dconf.nix
  ]
  # Plasma: plasma-manager settings
    ++ (if desktop == "plasma" then
      [ ../../../modules/home/plasma/plasma.nix ]
    else
      [ ]);

  # Enable font configuration for GUI apps
  fonts.fontconfig.enable = true;

  # Desktop-specific services
  services.syncthing.enable = true;

  # Desktop-specific program configurations
  # programs.firefox.enable = true;
  # ... etc ...
}
