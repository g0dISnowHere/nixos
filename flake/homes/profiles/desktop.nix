{ config, pkgs, pkgs-unstable, inputs, desktop ? null, ... }: {
  # Desktop profile
  # Extends common profile with GUI applications and DE-specific settings
  # Use this profile for workstations and GUI-enabled machines
  # DE-specific settings are conditionally imported based on the active desktop environment

  imports = [
    ./common.nix
    ../../../modules/home/services/keyring-backup.nix
  ]
  # GNOME: dconf settings
    ++ (if desktop == "gnome" then
      [
        # ../../../modules/home/dconf/dconf.nix 
      ]
    else
      [ ])
    # Plasma: plasma-manager settings
    ++ (if desktop == "plasma" then
      [ ../../../modules/home/plasma/plasma.nix ]
    else
      [ ])
    # Niri: dotfiles link script + compositor-specific home setup
    ++ (if desktop == "niri" then
      [ ../../../modules/home/desktop/niri.nix ]
    else
      [ ]);

  # Enable font configuration for GUI apps
  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts = {
    monospace = [ "JetBrainsMono Nerd Font Mono" ];
    sansSerif = [ "Noto Sans" "Cantarell" ];
    serif = [ "Noto Serif" ];
    emoji = [ "Noto Color Emoji" ];
  };

  # Desktop-specific services
  services.syncthing.enable = true;

  # Desktop-specific program configurations
  # programs.firefox.enable = true;
  # ... etc ...
}
