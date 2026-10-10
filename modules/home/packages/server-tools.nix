{ pkgs, ... }:
{
  home.packages = with pkgs; [
    esptool
    libnotify
    parted
    syncthing
    wireshark-cli
    wl-clipboard
  ];
}
