{ pkgs, ... }: {
  imports = [ ../../profiles/base.nix ./personal.nix ];

  # Karaka keeps a smaller GUI/user app set than the main workstation profile.
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
