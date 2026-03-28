{ config, dotfilesRoot, lib, ... }:
let
  noctaliaRoot = "${dotfilesRoot}/modules/ui/noctalia";
  noctaliaConfigHome = "${config.xdg.configHome}/noctalia";
in {
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

  # Noctalia writes plugin downloads and runtime state under ~/.config/noctalia.
  # Keep the directory writable and create direct symlinks into the working tree
  # so Noctalia can update files without going through an immutable store copy.
  home.activation.noctaliaWritableConfig =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      target="${noctaliaConfigHome}"

      if [ -L "$target" ]; then
        rm -f "$target"
      elif [ -f "$target" ]; then
        mv "$target" "$target.pre-home-manager"
      fi

      mkdir -p "$target"

      if [ -e "$target/settings.json" ] && [ ! -L "$target/settings.json" ]; then
        mv "$target/settings.json" "$target/settings.json.pre-home-manager"
      fi
      ln -sfn "${noctaliaRoot}/settings.json" "$target/settings.json"

      if [ -e "$target/plugins.json" ] && [ ! -L "$target/plugins.json" ]; then
        mv "$target/plugins.json" "$target/plugins.json.pre-home-manager"
      fi
      ln -sfn "${noctaliaRoot}/plugins.json" "$target/plugins.json"

      if [ -e "$target/colors.json" ] && [ ! -L "$target/colors.json" ]; then
        mv "$target/colors.json" "$target/colors.json.pre-home-manager"
      fi
      ln -sfn "${noctaliaRoot}/colors.json" "$target/colors.json"

      if [ -e "$target/plugins" ] && [ ! -L "$target/plugins" ]; then
        mv "$target/plugins" "$target/plugins.pre-home-manager"
      fi
      ln -sfn "${noctaliaRoot}/plugins" "$target/plugins"

      if [ -e "$target/colorschemes" ] && [ ! -L "$target/colorschemes" ]; then
        mv "$target/colorschemes" "$target/colorschemes.pre-home-manager"
      fi
      ln -sfn "${noctaliaRoot}/colorschemes" "$target/colorschemes"
    '';
}
