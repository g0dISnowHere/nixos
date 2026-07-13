{ ... }: {
  # GUI profile
  # Extends the base profile with GUI applications and DE-specific settings
  # Use this profile for GUI-enabled machines

  imports = [
    ./base.nix
    ../../../modules/home/packages/fonts-and-docs.nix
    ../../../modules/home/packages/desktop-apps.nix
    ../../../modules/home/packages/maker-tools.nix
    ../../../modules/home/services/keyring-backup.nix
  ];

  # Enable font configuration for GUI apps
  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts = {
    monospace = [ "JetBrainsMono Nerd Font Mono" ];
    sansSerif = [
      "Noto Sans"
      "Cantarell"
    ];
    serif = [ "Noto Serif" ];
    emoji = [ "Noto Color Emoji" ];
  };

  # Desktop-specific services
  services.syncthing.enable = true;

  # Desktop-specific program configurations
  # programs.firefox.enable = true;
  # ... etc ...
}
