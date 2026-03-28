{ config, dotfilesRoot, pkgs, ... }:

{
  home.packages = with pkgs; [
    nautilus
    nautilus-python
    file-roller
    sushi
    ffmpegthumbnailer
    loupe
    evince
    exiftool
    imagemagick
    cifs-utils
    sshfs
    unrar
    wl-clipboard
    libnotify
  ];

  home.file.".local/share/nautilus/scripts".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesRoot}/modules/nautilus/scripts";
  home.file.".local/share/nautilus-python/extensions".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesRoot}/modules/nautilus/extensions";

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    "application/x-gnome-saved-search" = [ "org.gnome.Nautilus.desktop" ];
    "application/pdf" = [ "org.gnome.Evince.desktop" ];
    "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
    "image/png" = [ "org.gnome.Loupe.desktop" ];
    "image/webp" = [ "org.gnome.Loupe.desktop" ];
  };
}
