{ config, dotfilesRoot, ... }: {
  xdg.configFile."niri/config.kdl".source = config.lib.file.mkOutOfStoreSymlink
    "${dotfilesRoot}/modules/compositor/niri/config.kdl";
  xdg.configFile."niri/swaylock-noctalia.sh".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesRoot}/modules/compositor/niri/swaylock-noctalia.sh";
  xdg.configFile."nirinit".source = config.lib.file.mkOutOfStoreSymlink
    "${dotfilesRoot}/modules/compositor/nirinit";
  xdg.configFile."waybar".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/modules/ui/waybar";
  xdg.configFile."mako".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/modules/ui/mako";
  xdg.configFile."fuzzel".source = config.lib.file.mkOutOfStoreSymlink
    "${dotfilesRoot}/modules/launcher/fuzzel";
  xdg.configFile."noctalia".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/modules/ui/noctalia";
}
