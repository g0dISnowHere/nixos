{ pkgs, ... }:
{
  imports = [
    ../../profiles/base.nix
    ./personal.nix
  ];

  home.packages = with pkgs; [
    bitwarden-desktop
    firefox
    gparted
    nextcloud-client
    syncthing
    syncthingtray
    vlc
  ];

  services.syncthing.enable = true;
}
