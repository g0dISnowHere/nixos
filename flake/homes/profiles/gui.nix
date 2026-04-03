{ config, pkgs, pkgs-unstable, inputs, desktopEnvironment ? null, ... }: {
  # GUI profile
  # Extends the base profile with GUI applications and DE-specific settings
  # Use this profile for workstations and GUI-enabled machines
  # DE-specific settings are conditionally imported based on the active desktop environment

  imports = [
    ./base.nix
    ../../../modules/home/packages/fonts-and-docs.nix
    ../../../modules/home/packages/desktop-apps.nix
    ../../../modules/home/packages/maker-tools.nix
    ../../../modules/home/services/keyring-backup.nix
  ]
  # GNOME: dconf settings
    ++ (if desktopEnvironment == "gnome" then
      [
        # ../../../modules/home/dconf/dconf.nix 
      ]
    else
      [ ])
    # Plasma: plasma-manager settings
    ++ (if desktopEnvironment == "plasma" then
      [ ../../../modules/home/plasma/plasma.nix ]
    else
      [ ])
    # Niri: Home Manager-managed links to repo-backed desktop dotfiles
    ++ (if desktopEnvironment == "niri" then [
      ../../../modules/home/desktop/niri.nix
      ../../../modules/home/packages/nautilus.nix
    ] else
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
