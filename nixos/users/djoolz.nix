{ config, pkgs, pkgs-unstable, lib, ... }:

{
  # User-specific home-manager configuration
  # TODO: Make username configurable through specialArgs
  home.username = "djoolz";
  home.homeDirectory = "/home/djoolz";

  fonts.fontconfig.enable = true;
  # home.packages = with pkgs; 
  # [
  #   cantarell-fonts
  # ];

  # Import modular home configuration
  imports = [
    # ./modules/flatpak.nix # doesn't work here for some reason
    ./modules/packages.nix
    ./modules/programs.nix
    # ./modules/shell.nix
    ../machines/common/virtualisation/quickemu.nix
  ];
  services.syncthing.enable = true;
  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  home.stateVersion = "24.11";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
