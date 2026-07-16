{ ... }:
{
  imports = [
    ../../../../modules/home/packages/fonts-and-docs.nix
    ../../../../modules/home/packages/desktop-apps.nix
    ../../../../modules/home/packages/maker-tools.nix
    ../../../../modules/home/services/keyring-backup.nix
  ];

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

  services.syncthing.enable = true;
}
