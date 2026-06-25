{ pkgs, ... }: {
  home.packages = with pkgs; [
    vlc
    wireshark
    webcamoid
    libnotify
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
