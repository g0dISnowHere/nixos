# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/Console" = {
      last-window-maximised = false;
      last-window-size = mkTuple [ 732 528 ];
    };

    "org/gnome/Weather" = {
      locations = [
        (mkVariant [
          (mkUint32 2)
          (mkVariant [
            "Dresden"
            "EDDC"
            true
            [ (mkTuple [ 0.8924450183686697 0.2399827721492203 ]) ]
            [ (mkTuple [ 0.8909905831431052 0.2399827721492203 ]) ]
          ])
        ])
      ];
      window-height = 494;
      window-maximized = false;
      window-width = 439;
    };

    "org/gnome/calculator" = {
      base = 10;
      button-mode = "basic";
      source-currency = "";
      source-units = "degree";
      target-currency = "";
      target-units = "radian";
      window-maximized = false;
      window-size = mkTuple [ 360 616 ];
    };

    "org/gnome/control-center" = {
      last-panel = "wifi";
      window-state = mkTuple [ 980 640 false ];
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [ "System" "Utilities" "YaST" "Pardus" ];
    };

    "org/gnome/desktop/app-folders/folders/Pardus" = {
      categories = [ "X-Pardus-Apps" ];
      name = "X-Pardus-Apps.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/System" = {
      apps = [
        "org.gnome.baobab.desktop"
        "org.gnome.DiskUtility.desktop"
        "org.gnome.Logs.desktop"
        "org.gnome.SystemMonitor.desktop"
      ];
      name = "X-GNOME-Shell-System.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [
        "org.gnome.Connections.desktop"
        "org.gnome.Evince.desktop"
        "org.gnome.FileRoller.desktop"
        "org.gnome.font-viewer.desktop"
        "org.gnome.Loupe.desktop"
        "org.gnome.seahorse.Application.desktop"
      ];
      name = "X-GNOME-Shell-Utilities.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/YaST" = {
      categories = [ "X-SuSE-YaST" ];
      name = "suse-yast.directory";
      translate = true;
    };

    "org/gnome/desktop/input-sources" = {
      sources = [ (mkTuple [ "xkb" "de" ]) ];
      xkb-options = [ ];
    };

    "org/gnome/desktop/notifications" = {
      application-children = [ "gnome-power-panel" ];
    };

    "org/gnome/desktop/notifications/application/gnome-power-panel" = {
      application-id = "gnome-power-panel.desktop";
    };

    "org/gnome/evolution-data-server" = { migrated = true; };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
    };

    "org/gnome/nautilus/window-state" = {
      initial-size = mkTuple [ 890 550 ];
      initial-size-file-chooser = mkTuple [ 890 550 ];
    };

    "org/gnome/shell" = { welcome-dialog-last-shown-version = "48.2"; };

    "org/gnome/shell/weather" = {
      automatic-location = true;
      locations = [
        (mkVariant [
          (mkUint32 2)
          (mkVariant [
            "Dresden"
            "EDDC"
            true
            [ (mkTuple [ 0.8924450183686697 0.2399827721492203 ]) ]
            [ (mkTuple [ 0.8909905831431052 0.2399827721492203 ]) ]
          ])
        ])
      ];
    };

    "org/gnome/shell/world-clocks" = { locations = [ ]; };

    "org/gnome/software" = {
      check-timestamp = mkInt64 1754905697;
      first-run = false;
    };

    "org/gtk/gtk4/settings/file-chooser" = { show-hidden = true; };

  };
}
