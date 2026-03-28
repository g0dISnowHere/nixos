{ pkgs, ... }: {
  home.packages = with pkgs; [
    vlc
    wireshark
    webcamoid
    bitwarden-desktop
    moonlight-qt
    nextcloud-client
    gparted
    obs-studio
    synology-drive-client
    syncthing
    obsidian
    chromium
  ];
}
