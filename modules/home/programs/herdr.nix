{ config, dotfilesRoot, ... }:
{
  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/modules/terminal/herdr/config.toml";
}
