# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "apps/seahorse/listing" = {
      keyrings-selected = [
        "pkcs11:model=p11-kit-trust;manufacturer=PKCS%2311%20Kit;serial=1;token=System%20Trust"
      ];
    };

    "apps/seahorse/windows/key-manager" = {
      height = 1001;
      width = 1920;
    };

    "ca/desrt/dconf-editor" = {
      saved-pathbar-path = "/org/gnome/";
      saved-view = "/org/";
      window-height = 500;
      window-is-maximized = true;
      window-width = 540;
    };

    "org/freedesktop/tracker/miner/files" = {
      index-recursive-directories = [
        "&DESKTOP"
        "&DOCUMENTS"
        "&MUSIC"
        "&PICTURES"
        "&VIDEOS"
        "/home/djoolz/Nextcloud"
        "/home/djoolz/SynologyDrive"
      ];
      index-single-directories = [ "$HOME" "&DOWNLOAD" ];
    };

    "org/gnome/Console" = {
      last-window-maximised = false;
      last-window-size = mkTuple [ 1910 1048 ];
    };

    "org/gnome/Extensions" = {
      window-height = 900;
      window-maximized = false;
      window-width = 584;
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
    };

    "org/gnome/calculator" = {
      accuracy = 9;
      angle-units = "degrees";
      base = 10;
      button-mode = "basic";
      number-format = "automatic";
      show-thousands = false;
      show-zeroes = false;
      source-currency = "";
      source-units = "degree";
      target-currency = "";
      target-units = "radian";
      window-maximized = false;
      window-size = mkTuple [ 360 1038 ];
      word-size = 64;
    };

    "org/gnome/calendar" = { active-view = "month"; };

    "org/gnome/control-center" = {
      last-panel = "wifi";
      window-state = mkTuple [ 1910 1048 false ];
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [ "Utilities" "YaST" "Pardus" ];
    };

    "org/gnome/desktop/app-folders/folders/Pardus" = {
      categories = [ "X-Pardus-Apps" ];
      name = "X-Pardus-Apps.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [
        "gnome-abrt.desktop"
        "gnome-system-log.desktop"
        "nm-connection-editor.desktop"
        "org.gnome.baobab.desktop"
        "org.gnome.Connections.desktop"
        "org.gnome.DejaDup.desktop"
        "org.gnome.Dictionary.desktop"
        "org.gnome.DiskUtility.desktop"
        "org.gnome.Evince.desktop"
        "org.gnome.FileRoller.desktop"
        "org.gnome.fonts.desktop"
        "org.gnome.Loupe.desktop"
        "org.gnome.seahorse.Application.desktop"
        "org.gnome.tweaks.desktop"
        "org.gnome.Usage.desktop"
        "vinagre.desktop"
      ];
      categories = [ "X-GNOME-Utilities" ];
      name = "X-GNOME-Utilities.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/YaST" = {
      categories = [ "X-SuSE-YaST" ];
      name = "suse-yast.directory";
      translate = true;
    };

    "org/gnome/desktop/background" = {
      picture-options = "zoom";
      picture-uri =
        "file:///home/djoolz/Pictures/BingWallpaper/20250609-AerialEverglades_DE-DE7864298334_UHD.jpg";
      picture-uri-dark =
        "file:///home/djoolz/Pictures/BingWallpaper/20250609-AerialEverglades_DE-DE7864298334_UHD.jpg";
    };

    "org/gnome/desktop/input-sources" = {
      sources = [ (mkTuple [ "xkb" "de" ]) ];
      xkb-options = [ "terminate:ctrl_alt_bksp" ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-theme = "Adwaita";
      enable-hot-corners = false;
      font-antialiasing = "grayscale";
      font-hinting = "slight";
      gtk-theme = "Adwaita";
      icon-theme = "Adwaita";
      show-battery-percentage = true;
    };

    "org/gnome/desktop/notifications" = {
      application-children = [
        "org-gnome-console"
        "org-gnome-settings"
        "firefox"
        "gnome-power-panel"
        "org-gnome-software"
        "org-freecad-freecad"
        "org-signal-signal"
        "org-mozilla-thunderbird"
        "org-gnome-systemmonitor"
        "com-vivaldi-vivaldi"
        "org-gnome-nautilus"
        "code"
        "org-gnome-extensions"
        "com-nextcloud-desktopclient-nextcloud"
        "md-obsidian-obsidian"
        "org-libreoffice-libreoffice-calc"
        "org-gnome-texteditor"
        "io-dbeaver-dbeavercommunity"
        "org-nmap-zenmap"
        "io-github-omniaevo-mqtt5-explorer"
        "quickgui"
        "virt-manager"
        "com-spotify-client"
        "org-inkscape-inkscape"
        "org-libreoffice-libreoffice-draw"
        "com-moonlight-stream-moonlight"
      ];
      show-banners = true;
    };

    "org/gnome/desktop/notifications/application/code" = {
      application-id = "code.desktop";
    };

    "org/gnome/desktop/notifications/application/com-moonlight-stream-moonlight" =
      {
        application-id = "com.moonlight_stream.Moonlight.desktop";
      };

    "org/gnome/desktop/notifications/application/com-nextcloud-desktopclient-nextcloud" =
      {
        application-id = "com.nextcloud.desktopclient.nextcloud.desktop";
      };

    "org/gnome/desktop/notifications/application/com-spotify-client" = {
      application-id = "com.spotify.Client.desktop";
    };

    "org/gnome/desktop/notifications/application/com-vivaldi-vivaldi" = {
      application-id = "com.vivaldi.Vivaldi.desktop";
    };

    "org/gnome/desktop/notifications/application/firefox" = {
      application-id = "firefox.desktop";
    };

    "org/gnome/desktop/notifications/application/gnome-power-panel" = {
      application-id = "gnome-power-panel.desktop";
    };

    "org/gnome/desktop/notifications/application/io-dbeaver-dbeavercommunity" =
      {
        application-id = "io.dbeaver.DBeaverCommunity.desktop";
      };

    "org/gnome/desktop/notifications/application/io-github-omniaevo-mqtt5-explorer" =
      {
        application-id = "io.github.Omniaevo.mqtt5-explorer.desktop";
      };

    "org/gnome/desktop/notifications/application/md-obsidian-obsidian" = {
      application-id = "md.obsidian.Obsidian.desktop";
    };

    "org/gnome/desktop/notifications/application/org-freecad-freecad" = {
      application-id = "org.freecad.FreeCAD.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-console" = {
      application-id = "org.gnome.Console.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-extensions" = {
      application-id = "org.gnome.Extensions.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-nautilus" = {
      application-id = "org.gnome.Nautilus.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-settings" = {
      application-id = "org.gnome.Settings.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-software" = {
      application-id = "org.gnome.Software.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-systemmonitor" = {
      application-id = "org.gnome.SystemMonitor.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-texteditor" = {
      application-id = "org.gnome.TextEditor.desktop";
    };

    "org/gnome/desktop/notifications/application/org-inkscape-inkscape" = {
      application-id = "org.inkscape.Inkscape.desktop";
    };

    "org/gnome/desktop/notifications/application/org-libreoffice-libreoffice-calc" =
      {
        application-id = "org.libreoffice.LibreOffice.calc.desktop";
      };

    "org/gnome/desktop/notifications/application/org-libreoffice-libreoffice-draw" =
      {
        application-id = "org.libreoffice.LibreOffice.draw.desktop";
      };

    "org/gnome/desktop/notifications/application/org-mozilla-thunderbird" = {
      application-id = "org.mozilla.Thunderbird.desktop";
    };

    "org/gnome/desktop/notifications/application/org-nmap-zenmap" = {
      application-id = "org.nmap.Zenmap.desktop";
    };

    "org/gnome/desktop/notifications/application/org-signal-signal" = {
      application-id = "org.signal.Signal.desktop";
    };

    "org/gnome/desktop/notifications/application/quickgui" = {
      application-id = "quickgui.desktop";
    };

    "org/gnome/desktop/notifications/application/virt-manager" = {
      application-id = "virt-manager.desktop";
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      accel-profile = "flat";
      speed = 0.4887218045112782;
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/search-providers" = {
      sort-order = [
        "org.gnome.Settings.desktop"
        "org.gnome.Contacts.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };

    "org/gnome/desktop/sound" = {
      event-sounds = false;
      theme-name = "__custom";
    };

    "org/gnome/desktop/wm/keybindings" = {
      maximize = [ ];
      move-to-monitor-down = [ ];
      move-to-monitor-left = [ ];
      move-to-monitor-right = [ ];
      move-to-monitor-up = [ ];
      move-to-workspace-down = [ ];
      move-to-workspace-left = [ "<Super><Shift>Page_Up" ];
      move-to-workspace-right = [ "<Super><Shift>Page_Down" ];
      move-to-workspace-up = [ ];
      switch-applications = [ ];
      switch-applications-backward = [ ];
      switch-group = [ ];
      switch-group-backward = [ ];
      switch-panels = [ ];
      switch-panels-backward = [ ];
      switch-to-workspace-1 = [ ];
      switch-to-workspace-down = [ "<Control><Alt>Down" ];
      switch-to-workspace-last = [ ];
      switch-to-workspace-left = [ ];
      switch-to-workspace-right = [ ];
      switch-to-workspace-up = [ "<Control><Alt>Up" ];
      unmaximize = [ ];
    };

    "org/gnome/desktop/wm/preferences" = {
      action-double-click-titlebar = "toggle-maximize";
      action-middle-click-titlebar = "none";
      action-right-click-titlebar = "menu";
      button-layout = "appmenu:close";
      focus-mode = "click";
      num-workspaces = 4;
      workspace-names = [ "" "" "" "Workspace 4" "Workspace 5" ];
    };

    "org/gnome/evolution-data-server" = { migrated = true; };

    "org/gnome/file-roller/dialogs/extract" = {
      height = 800;
      recreate-folders = true;
      skip-newer = false;
      width = 1000;
    };

    "org/gnome/file-roller/file-selector" = {
      show-hidden = false;
      sidebar-size = 300;
      sort-method = "name";
      sort-type = "ascending";
      window-size = mkTuple [ (-1) (-1) ];
    };

    "org/gnome/file-roller/listing" = {
      list-mode = "as-folder";
      name-column-width = 65;
      show-path = false;
      sort-method = "name";
      sort-type = "ascending";
    };

    "org/gnome/file-roller/ui" = {
      sidebar-width = 200;
      window-height = 1048;
      window-width = 600;
    };

    "org/gnome/gnome-system-monitor" = {
      current-tab = "resources";
      show-dependencies = false;
      show-whose-processes = "user";
      window-height = 1048;
      window-width = 1440;
    };

    "org/gnome/gnome-system-monitor/proctree" = {
      col-26-visible = false;
      col-26-width = 0;
      columns-order = [
        0
        12
        1
        2
        3
        4
        6
        7
        8
        9
        10
        11
        13
        14
        15
        16
        17
        18
        19
        20
        21
        22
        23
        24
        25
        26
      ];
      sort-col = 15;
      sort-order = 0;
    };

    "org/gnome/mutter" = {
      attach-modal-dialogs = false;
      dynamic-workspaces = true;
      edge-tiling = false;
      workspaces-only-on-primary = false;
    };

    "org/gnome/mutter/keybindings" = {
      cancel-input-capture = [ ];
      toggle-tiled-left = [ ];
      toggle-tiled-right = [ ];
    };

    "org/gnome/mutter/wayland/keybindings" = { restore-shortcuts = [ ]; };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
    };

    "org/gnome/nautilus/window-state" = {
      initial-size = mkTuple [ 1910 1048 ];
      initial-size-file-chooser = mkTuple [ 890 1038 ];
      maximized = true;
    };

    "org/gnome/nm-applet/eap/10f5068e-af02-414f-a261-74a34f9c1bbb" = {
      ignore-ca-cert = false;
      ignore-phase2-ca-cert = false;
    };

    "org/gnome/nm-applet/eap/38ec6d84-0d99-3621-afb0-c1920b4c83cf" = {
      ignore-ca-cert = false;
      ignore-phase2-ca-cert = false;
    };

    "org/gnome/nm-applet/eap/55de461a-de5a-4f15-8f2f-96e09fcffa28" = {
      ignore-ca-cert = false;
      ignore-phase2-ca-cert = false;
    };

    "org/gnome/nm-applet/eap/5e1b373f-2c61-3951-b5a4-d46d51a0d1d7" = {
      ignore-ca-cert = false;
      ignore-phase2-ca-cert = false;
    };

    "org/gnome/portal/filechooser/code" = {
      last-folder-path = "/home/djoolz/Documents/02_docker";
    };

    "org/gnome/portal/filechooser/com/vivaldi/Vivaldi" = {
      last-folder-path =
        "/home/djoolz/Documents/13_virtual_machines/homeassistant";
    };

    "org/gnome/portal/filechooser/io/dbeaver/DBeaverCommunity" = {
      last-folder-path = "/home/djoolz/Documents/12_contact_scrape";
    };

    "org/gnome/portal/filechooser/md/obsidian/Obsidian" = {
      last-folder-path = "/home/djoolz/Documents/mine";
    };

    "org/gnome/portal/filechooser/obsidian" = {
      last-folder-path = "/home/djoolz/Documents/mine";
    };

    "org/gnome/portal/filechooser/org/signal/Signal" = {
      last-folder-path = "/home/djoolz/Documents/12_contact_scrape";
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = false;
      night-light-schedule-automatic = false;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      rotate-video-lock-static = [ ];
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
    };

    "org/gnome/shell" = {
      command-history = [ "r" ];
      disabled-extensions = [
        "Battery-Health-Charging@maniacx.github.com"
        "places-menu@gnome-shell-extensions.gcampax.github.com"
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "system-monitor-next@paradoxxx.zero.gmail.com"
        "pomodoro@arun.codito.in"
        "status-icons@gnome-shell-extensions.gcampax.github.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        "window-list@gnome-shell-extensions.gcampax.github.com"
        "drive-menu@gnome-shell-extensions.gcampax.github.com"
        "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
        "light-style@gnome-shell-extensions.gcampax.github.com"
        "extension-list@tu.berry"
        "windowsNavigator@gnome-shell-extensions.gcampax.github.com"
        "power-profile-switcher@eliapasquali.github.io"
        "vertical-workspaces@G-dH.github.com"
        "clipboard-history@alexsaveau.dev"
        "workspace-switcher-manager@G-dH.github.com"
        "pano@elhan.io"
        "gsconnect@andyholmes.github.io"
      ];
      enabled-extensions = [
        "batterythreshold@francku.gitlab.com"
        "thinkpad-battery-threshold@marcosdalvarez.org"
        "privacy-indicators-accent-color@sopht.li"
        "Vitals@CoreCoding.com"
        "BingWallpaper@ineffable-gmail.com"
        "caffeine@patapon.info"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        "native-window-placement@gnome-shell-extensions.gcampax.github.com"
        "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com"
        "windows-search-provider@G-dH.github.com"
        "extensions-search-provider@G-dH.github.com"
        "window-thumbnails@G-dH.github.com"
        "quick-settings-tweaks@qwreey"
        "auto-power-profile@dmy3k.github.io"
        "trayIconsReloaded@selfmade.pl"
        "paperwm@paperwm.github.com"
        "clipboard-indicator@tudmotu.com"
        "another-window-session-manager@gmail.com"
        "appindicatorsupport@rgcjonas.gmail.com"
      ];
      favorite-apps = [ "org.gnome.Nautilus.desktop" ];
      last-selected-power-profile = "performance";
      welcome-dialog-last-shown-version = "47.1";
    };

    "org/gnome/shell/extensions/Battery-Health-Charging" = {
      default-threshold = true;
      device-type = 20;
      dummy-default-threshold = true;
      icon-style-type = 2;
      polkit-status = "not-installed";
    };

    "org/gnome/shell/extensions/another-window-session-manager" = {
      close-windows-rules = ''
        {}
      '';
      close-windows-rules-by-keyword = ''
        {}
      '';
      close-windows-whitelist = ''
        {"2":{"id":2,"compareWith":"wm_class","method":"equals","enabled":false,"enableWhenCloseWindows":false,"enableWhenLogout":true,"name":"Vivaldi-flatpak"},"152":{"id":152,"compareWith":"wm_class","method":"equals","enabled":false,"enableWhenCloseWindows":true,"enableWhenLogout":true,"name":"Code"}}
      '';
      enable-autoclose-session = true;
      enable-close-by-rules = false;
      enable-restore-previous-session = true;
      windows-mapping = ''
        [["Unknown",{"W92 ([untitled])":{"windowTitle":null,"xid":"W92 ([untitled])","windowStableSequence":93}}],["/nix/store/5zlvmahsqdkgpqm5m0z5nqmh6j8zbf5b-gnome-shell-48.1/share/applications/org.gnome.Extensions.desktop",{"W82 ([untitled])":{"windowTitle":null,"xid":"W82 ([untitled])","windowStableSequence":83}}],["/var/lib/flatpak/exports/share/applications/com.spotify.Client.desktop",{"0x1800004 (Spotify)":{"windowTitle":"Spotify","xid":"0x1800004 (Spotify)","windowStableSequence":6}}],["/etc/profiles/per-user/djoolz/share/applications/code.desktop",{"0x220d6a3 (Visual Studio Code)":{"windowTitle":"Visual Studio Code","xid":"0x220d6a3 (Visual Studio Code)","windowStableSequence":192}}],["/etc/profiles/per-user/djoolz/share/applications/obsidian.desktop",{"0x1400004 (mine - Obsidian v1.8.10)":{"windowTitle":"mine - Obsidian v1.8.10","xid":"0x1400004 (mine - Obsidian v1.8.10)","windowStableSequence":11}}],["/var/lib/flatpak/exports/share/applications/com.vivaldi.Vivaldi.desktop",{"0x2a000bf (Vivaldi - Vivaldi)":{"windowTitle":"Vivaldi - Vivaldi","xid":"0x2a000bf (Vivaldi - Vivaldi)","windowStableSequence":172}}],["/var/lib/flatpak/exports/share/applications/org.signal.Signal.desktop",{"0x3e00004 (Signal)":{"windowTitle":"Signal","xid":"0x3e00004 (Signal)","windowStableSequence":18}}],["/run/current-system/sw/share/applications/org.gnome.Nautilus.desktop",{"W110 ([untitled])":{"windowTitle":null,"xid":"W110 ([untitled])","windowStableSequence":111}}],["/run/current-system/sw/share/applications/org.gnome.Settings.desktop",{"W60 ([untitled])":{"windowTitle":null,"xid":"W60 ([untitled])","windowStableSequence":61}}],["/run/current-system/sw/share/applications/virt-manager.desktop",{"W71 ([untitled])":{"windowTitle":null,"xid":"W71 ([untitled])","windowStableSequence":72}}],["/run/current-system/sw/share/applications/org.gnome.Console.desktop",{"W86 ([untitled])":{"windowTitle":null,"xid":"W86 ([untitled])","windowStableSequence":87}}]]'';
    };

    "org/gnome/shell/extensions/appindicator" = {
      icon-brightness = 0.0;
      icon-contrast = 0.0;
      icon-opacity = 240;
      icon-saturation = 0.0;
      icon-size = 0;
    };

    "org/gnome/shell/extensions/auto-move-windows" = {
      application-list = [
        "bitwarden.desktop:1"
        "org.signal.Signal.desktop:1"
        "org.mozilla.Thunderbird.desktop:1"
        "com.spotify.Client.desktop:1"
        "firefox.desktop:1"
        "btop.desktop:1"
        "org.gnome.Shell.Extensions.desktop:1"
        "obsidian.desktop:1"
        "org.gnome.Settings.desktop:1"
      ];
    };

    "org/gnome/shell/extensions/auto-power-profile" = { bat = "balanced"; };

    "org/gnome/shell/extensions/bingwallpaper" = {
      bing-json = ''
        [{"startdate":"20250325","fullstartdate":"202503252300","enddate":"20250326","url":"/th?id=OHR.CrystalManatee_DE-DE8276334869_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.CrystalManatee_DE-DE8276334869","copyright":"Rundschwanzseekuh in Crystal River, Florida, USA (169 Stephen Frink/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Rundschwanzseek%C3%BChe&form=hpcapt&filters=HpDate%3a%2220250325_2300%22","title":"Sanfte Riesen","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250325_CrystalManatee%22&FORM=HPQUIZ","wp":true,"hsh":"1eeda3323a3c7453db6917a45eb3019c","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250326","fullstartdate":"202503262300","enddate":"20250327","url":"/th?id=OHR.OdeonAthens_DE-DE3749163988_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.OdeonAthens_DE-DE3749163988","copyright":"Odeon des Herodes Atticus, Akropolis von Athen, Griechenland (169 f11photo/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Welttag+des+Theaters&form=hpcapt&filters=HpDate%3a%2220250326_2300%22","title":"Allen Theatern einen herzlichen Applaus!","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250326_OdeonAthens%22&FORM=HPQUIZ","wp":true,"hsh":"e5151b0b2b0b3ded94bf93519fd8ebd9","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250327","fullstartdate":"202503272300","enddate":"20250328","url":"/th?id=OHR.NestingMonarch_DE-DE4342475181_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.NestingMonarch_DE-DE4342475181","copyright":"Weiblicher Schwarzgenickschn228pper im Nest (169 komkrit tonusin/Alamy)","copyrightlink":"https://www.bing.com/search?q=Schwarzgenickschn%C3%A4pper&form=hpcapt&filters=HpDate%3a%2220250327_2300%22","title":"Bunt gefiederter Freund","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250327_NestingMonarch%22&FORM=HPQUIZ","wp":true,"hsh":"a806e0317093e708c5950a75151bcf8e","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250328","fullstartdate":"202503282300","enddate":"20250329","url":"/th?id=OHR.CarrizoBloom_DE-DE4724342753_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.CarrizoBloom_DE-DE4724342753","copyright":"Superbloom in Carrizo Plain National Monument, Kalifornien, USA (169 Robb Hirsch/TANDEM Stills + Motion)","copyrightlink":"https://www.bing.com/search?q=Superbl%C3%BCte+Kalifornien&form=hpcapt&filters=HpDate%3a%2220250328_2300%22","title":"Endloses Bl252tenmeer","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250328_CarrizoBloom%22&FORM=HPQUIZ","wp":true,"hsh":"51cedb8cd14ccf8efbb11e3b2cc3c359","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250329","fullstartdate":"202503292300","enddate":"20250330","url":"/th?id=OHR.AtheneNoctuaGermany_DE-DE4640297200_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.AtheneNoctuaGermany_DE-DE4640297200","copyright":"Steinkauz-Junges in einem Baumloch (169 Bildagentur Zoonar GmbH/Alamy)","copyrightlink":"https://www.bing.com/search?q=Sommerzeit&form=hpcapt&filters=HpDate%3a%2220250329_2300%22","title":"Wer hat an der Uhr gedreht?","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250329_AtheneNoctuaGermany%22&FORM=HPQUIZ","wp":true,"hsh":"1c8fb2e5397ea20725d3310f622b2377","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250330","fullstartdate":"202503302200","enddate":"20250331","url":"/th?id=OHR.ItalyOstuni_DE-DE7873606461_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.ItalyOstuni_DE-DE7873606461","copyright":"Ostuni bei D228mmerung, Apulien, Italien (169 Feng Wei Photography/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Ostuni+Italien&form=hpcapt&filters=HpDate%3a%2220250330_2200%22","title":"Die 8222wei223e Stadt8220 von Apulien","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250330_ItalyOstuni%22&FORM=HPQUIZ","wp":true,"hsh":"80a7f41acbae96d0b3ecebdde0859e1d","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250331","fullstartdate":"202503312200","enddate":"20250401","url":"/th?id=OHR.TicanFrog_DE-DE8199372905_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.TicanFrog_DE-DE8199372905","copyright":"Kanalzonen-Baumfrosch, Costa Rica (169 Ondrej Prosicky/Shutterstock)","copyrightlink":"https://www.bing.com/search?q=Fr%C3%B6sche&form=hpcapt&filters=HpDate%3a%2220250331_2200%22","title":"Auf dem Sprung","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250331_TicanFrog%22&FORM=HPQUIZ","wp":true,"hsh":"f4a41ac714eadde58aebf58fa0b19209","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250401","fullstartdate":"202504012200","enddate":"20250402","url":"/th?id=OHR.UtahBadlands_DE-DE8578683347_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.UtahBadlands_DE-DE8578683347","copyright":"Sandsteinformationen in den Badlands bei Caineville, Utah, USA (169 Chris Moore/TANDEM Stills + Motion)","copyrightlink":"https://www.bing.com/search?q=Caineville+Utah&form=hpcapt&filters=HpDate%3a%2220250401_2200%22","title":"Bizarre Felsformationen","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250401_UtahBadlands%22&FORM=HPQUIZ","wp":true,"hsh":"b32cada48ddc3f7d4f51912962117a9c","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250402","fullstartdate":"202504022200","enddate":"20250403","url":"/th?id=OHR.SaguaroRainbow_DE-DE8863396941_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.SaguaroRainbow_DE-DE8863396941","copyright":"Regenbogen 252ber dem Wasson Peak, Saguaro-Nationalpark, Arizona, USA (169 Frank Staub/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Regenbogen+Besonderheiten&form=hpcapt&filters=HpDate%3a%2220250402_2200%22","title":"Farben der Freude","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250402_SaguaroRainbow%22&FORM=HPQUIZ","wp":true,"hsh":"fa404660a89568d8758adea6146ef629","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250403","fullstartdate":"202504032200","enddate":"20250404","url":"/th?id=OHR.IKMZLibrary_DE-DE3922270471_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.IKMZLibrary_DE-DE3922270471","copyright":"Informations-, Kommunikations- und Medienzentrum Cottbus, Brandenburg (169 H & D ZIELSKE/Gallery Stock)","copyrightlink":"https://www.bing.com/search?q=Nacht+der+Bibliotheken+2025&form=hpcapt&filters=HpDate%3a%2220250403_2200%22","title":"8222Wissen. Teilen. Entdecken.8220","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250403_IKMZLibrary%22&FORM=HPQUIZ","wp":true,"hsh":"92ad344ee61adb81f0b8ba98388b9948","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250404","fullstartdate":"202504042200","enddate":"20250405","url":"/th?id=OHR.GaztelugatxeSunset_DE-DE0917848827_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.GaztelugatxeSunset_DE-DE0917848827","copyright":"Insel Gaztelugatxe bei Sonnenuntergang, Baskenland, Spanien (169 Eloi_Omella/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Gaztelugatxe&form=hpcapt&filters=HpDate%3a%2220250404_2200%22","title":"Auf den Spuren der Einsiedler","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250404_GaztelugatxeSunset%22&FORM=HPQUIZ","wp":true,"hsh":"d1da8e9b442a4a668cc19e1e92bac338","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250405","fullstartdate":"202504052200","enddate":"20250406","url":"/th?id=OHR.PeabodyBaltimore_DE-DE8297645557_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.PeabodyBaltimore_DE-DE8297645557","copyright":"George Peabody Library, Baltimore, Maryland, USA (169 Wim Wiskerke/Alamy)","copyrightlink":"https://www.bing.com/search?q=George+Peabody+Library+Baltimore&form=hpcapt&filters=HpDate%3a%2220250405_2200%22","title":"Vom Buche verweht","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250405_PeabodyBaltimore%22&FORM=HPQUIZ","wp":false,"hsh":"8b82c635bb25555d1e2bb6c2a1cb7985","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250406","fullstartdate":"202504062200","enddate":"20250407","url":"/th?id=OHR.BeaverDay_DE-DE8403333829_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.BeaverDay_DE-DE8403333829","copyright":"Kanadischer Biber, Moran, Wyoming, USA (169 Enrique Aguirre Aves/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Internationaler+Bibertag&form=hpcapt&filters=HpDate%3a%2220250406_2200%22","title":"Die Ingenieure des 214kosystems","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250406_BeaverDay%22&FORM=HPQUIZ","wp":true,"hsh":"5e459ea91741c0ef5c61e55c52da453f","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250407","fullstartdate":"202504072200","enddate":"20250408","url":"/th?id=OHR.LagoaPortugal_DE-DE8623516787_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.LagoaPortugal_DE-DE8623516787","copyright":"Benagil-H246hle, Algarve, Portugal (169 Westend61/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Algarve+Portugal&form=hpcapt&filters=HpDate%3a%2220250407_2200%22","title":"Wo das Licht tanzt","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250407_LagoaPortugal%22&FORM=HPQUIZ","wp":true,"hsh":"1c9885f189c90d0ae45084a80c6e4d28","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250407","fullstartdate":"202504072200","enddate":"20250408","url":"/th?id=OHR.ParoTsechu_DE-DE2839281679_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.ParoTsechu_DE-DE2839281679","copyright":"Frauen in der Nationaltracht beim Paro Tshechu Festival in Bhutan (169 Richard I'Anson/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Paro+Tshechu+Festival&form=hpcapt&filters=HpDate%3a%2220250407_2200%22","title":"Muster aus der Vergangenheit","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250407_ParoTsechu%22&FORM=HPQUIZ","wp":true,"hsh":"a6fc2760d01cf2b956c52e920aa9745e","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250408","fullstartdate":"202504082200","enddate":"20250409","url":"/th?id=OHR.BlueNaxos_DE-DE2161075771_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.BlueNaxos_DE-DE2161075771","copyright":"Blaue Stunde auf Naxos, Kykladen, Griechenland (169 Sizun Eye/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Naxos+Griechenland&form=hpcapt&filters=HpDate%3a%2220250408_2200%22","title":"Bevor die Sterne die Macht 252bernehmen","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250408_BlueNaxos%22&FORM=HPQUIZ","wp":true,"hsh":"8bd9cd2326d6f18ae3406cb9af88d372","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250409","fullstartdate":"202504092200","enddate":"20250410","url":"/th?id=OHR.LittleFoxes_DE-DE1578546136_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.LittleFoxes_DE-DE1578546136","copyright":"Rotfuchsjunge in der N228he ihres Baus (169 WildMedia/Shutterstock)","copyrightlink":"https://www.bing.com/search?q=Tag+der+Geschwister&form=hpcapt&filters=HpDate%3a%2220250409_2200%22","title":"Neugierige Entdecker","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250409_LittleFoxes%22&FORM=HPQUIZ","wp":true,"hsh":"678f526fe0a3c50fdfea248ef22be1c6","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250410","fullstartdate":"202504102200","enddate":"20250411","url":"/th?id=OHR.TulipsWindmill_DE-DE0828527136_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.TulipsWindmill_DE-DE0828527136","copyright":"Tulpenfeld, Niederlande (169 1111IESPDJ/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Tulpen&form=hpcapt&filters=HpDate%3a%2220250410_2200%22","title":"Ein leuchtendes Blumenmeer","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250410_TulipsWindmill%22&FORM=HPQUIZ","wp":true,"hsh":"792178b81a039b980c76d61973ec43f6","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250411","fullstartdate":"202504112200","enddate":"20250412","url":"/th?id=OHR.SpaceFlight_DE-DE4206523074_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.SpaceFlight_DE-DE4206523074","copyright":"Blick aus der Kuppel der Internationalen Raumstation 252ber den S252dpazifik (169 NASA)","copyrightlink":"https://www.bing.com/search?q=Internationaler+Tag+der+bemannten+Raumfahrt+&form=hpcapt&filters=HpDate%3a%2220250411_2200%22","title":"108 Minuten, die die Welt ver228nderten","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250411_SpaceFlight%22&FORM=HPQUIZ","wp":true,"hsh":"63194f9d5f82a616469823d0cdc973da","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250412","fullstartdate":"202504122200","enddate":"20250413","url":"/th?id=OHR.ThailandPagodas_DE-DE3455777825_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.ThailandPagodas_DE-DE3455777825","copyright":"Wat Tang Sai Temple in Ban Krut, Thailand (169 Ratnakorn Piyasirisorost/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Songkran&form=hpcapt&filters=HpDate%3a%2220250412_2200%22","title":"Frohes Neues Songkran!","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250412_ThailandPagodas%22&FORM=HPQUIZ","wp":true,"hsh":"7fd11f0f1eed3835f9cc296f3c9b93c3","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250413","fullstartdate":"202504132200","enddate":"20250414","url":"/th?id=OHR.SpottedDolphins_DE-DE3167683290_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.SpottedDolphins_DE-DE3167683290","copyright":"Z252geldelfine in der N228he der Insel Santa Maria, Azoren, Portugal (169 Jordi Chias/Minden Pictures)","copyrightlink":"https://www.bing.com/search?q=Z%C3%BCgeldelfine&form=hpcapt&filters=HpDate%3a%2220250413_2200%22","title":"Die Akrobaten des Ozeans","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250413_SpottedDolphins%22&FORM=HPQUIZ","wp":true,"hsh":"eb003ccbb72c049adeefc6404651d344","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250414","fullstartdate":"202504142200","enddate":"20250415","url":"/th?id=OHR.BeachArt_DE-DE2496270870_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.BeachArt_DE-DE2496270870","copyright":"Sandkunst am Sauveterre Strand bei Zarpo, Les Sables-d'Olonne, Vendee, Frankreich (169 Hemis/Alamy)","copyrightlink":"https://www.bing.com/search?q=Weltkunsttag&form=hpcapt&filters=HpDate%3a%2220250414_2200%22","title":"Kunst erleben","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250414_BeachArt%22&FORM=HPQUIZ","wp":false,"hsh":"7167c8b11e4abc36eb07aa6debdae23f","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250415","fullstartdate":"202504152200","enddate":"20250416","url":"/th?id=OHR.BeachChairsSteinwarder_DE-DE2084587794_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.BeachChairsSteinwarder_DE-DE2084587794","copyright":"Strandk246rbe vor der Seebr252cke auf Steinwarder in Heiligenhafen, Schleswig-Holstein, Deutschland (169 Frank Lukasseck/Huber/eStock Photo)","copyrightlink":"https://www.bing.com/search?q=Heiligenhafen&form=hpcapt&filters=HpDate%3a%2220250415_2200%22","title":"Ostseezauber","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250415_BeachChairsSteinwarder%22&FORM=HPQUIZ","wp":true,"hsh":"436005186e4cb60074e164bce31e608c","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250416","fullstartdate":"202504162200","enddate":"20250417","url":"/th?id=OHR.EcuadorBird_DE-DE1431082236_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.EcuadorBird_DE-DE1431082236","copyright":"Andenfelsenh228hne, Ecuador (169 Kit Day/Alamy)","copyrightlink":"https://www.bing.com/search?q=Andenfelshahn&form=hpcapt&filters=HpDate%3a%2220250416_2200%22","title":"Dramatisches Duo","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250416_EcuadorBird%22&FORM=HPQUIZ","wp":true,"hsh":"dff30902badef38dbf8086f6de65270e","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250417","fullstartdate":"202504172200","enddate":"20250418","url":"/th?id=OHR.GoremeTurkey_DE-DE1882170025_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.GoremeTurkey_DE-DE1882170025","copyright":"Hei223luftballons 252ber dem Nationalpark G246reme in Kappadokien, T252rkei (169 Anton Petrus/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Internationaler+Denkmaltag&form=hpcapt&filters=HpDate%3a%2220250417_2200%22","title":"Die Geschichte feiern","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250417_GoremeTurkey%22&FORM=HPQUIZ","wp":true,"hsh":"33a11e18a3ba84e644557bd5ef6e5668","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250418","fullstartdate":"202504182200","enddate":"20250419","url":"/th?id=OHR.ZionValley_DE-DE1917937045_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.ZionValley_DE-DE1917937045","copyright":"Zion-Nationalpark, Utah, USA (169 Simon Dannhauer/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Zion-Nationalpark&form=hpcapt&filters=HpDate%3a%2220250418_2200%22","title":"Beeindruckende Weiten und Tiefen","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250418_ZionValley%22&FORM=HPQUIZ","wp":true,"hsh":"6f1857d0d2f5ead9aba41180de8eb020","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250419","fullstartdate":"202504192200","enddate":"20250420","url":"/th?id=OHR.EastereggsTree_DE-DE3677882321_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.EastereggsTree_DE-DE3677882321","copyright":"Viele bunt bemalte Ostereier an einem Apfelbaum (169 Kerrick/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Ostern&form=hpcapt&filters=HpDate%3a%2220250419_2200%22","title":"Frohe Ostern!","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250419_EastereggsTree%22&FORM=HPQUIZ","wp":true,"hsh":"68ac2ce6a8ae23dae84f35e8109ee293","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250420","fullstartdate":"202504202200","enddate":"20250421","url":"/th?id=OHR.JoshuaStars_DE-DE4771713346_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.JoshuaStars_DE-DE4771713346","copyright":"Josuab228ume unter der Milchstra223e, Kalifornien, USA (169 Chao Zhang/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Internationale+Woche+des+dunklen+Himmels&form=hpcapt&filters=HpDate%3a%2220250420_2200%22","title":"Die Magie der Sterne","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250420_JoshuaStars%22&FORM=HPQUIZ","wp":true,"hsh":"b02ea6622c9b0d9739cf022d4516afbf","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250421","fullstartdate":"202504212200","enddate":"20250422","url":"/th?id=OHR.YellowstoneSpring_DE-DE2924046360_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.YellowstoneSpring_DE-DE2924046360","copyright":"Grand Prismatic Spring, Yellowstone-Nationalpark, Wyoming, USA (169 Ajith Kumar/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Tag+der+Erde&form=hpcapt&filters=HpDate%3a%2220250421_2200%22","title":"Ver228nderung beginnt mit Engagement","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250421_YellowstoneSpring%22&FORM=HPQUIZ","wp":true,"hsh":"4d9d399434c0d7cb0a50ed93b08847c7","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250422","fullstartdate":"202504222200","enddate":"20250423","url":"/th?id=OHR.GlobeTheatre_DE-DE3738219615_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.GlobeTheatre_DE-DE3738219615","copyright":"Shakespeares Globe Theatre, London, England (169 Peter Dazeley/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Shakespeare+Geburtstag&form=hpcapt&filters=HpDate%3a%2220250422_2200%22","title":"Viel L228rm um Shakespeare","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250422_GlobeTheatre%22&FORM=HPQUIZ","wp":false,"hsh":"1865142b92f30adea0ccae53d80b3786","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250423","fullstartdate":"202504232200","enddate":"20250424","url":"/th?id=OHR.KenaiSpires_DE-DE8277470819_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.KenaiSpires_DE-DE8277470819","copyright":"Spire Cove im Kenai-Fjords-Nationalpark, Seward, Alaska, USA (169 Wander Photography/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Kenai-Fjords-Nationalpark&form=hpcapt&filters=HpDate%3a%2220250423_2200%22","title":"Raue Gipfel und wilde Gew228sser","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250423_KenaiSpires%22&FORM=HPQUIZ","wp":true,"hsh":"3fd036e37fd4c13579308059b17a572a","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250424","fullstartdate":"202504242200","enddate":"20250425","url":"/th?id=OHR.MagellanicPenguin_DE-DE2240102652_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.MagellanicPenguin_DE-DE2240102652","copyright":"Magellanpinguine, Volunteer Point, Falklandinseln (169 imageBROKER/Matthias Graben/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Pinguine&form=hpcapt&filters=HpDate%3a%2220250424_2200%22","title":"Matrosen im Smoking","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250424_MagellanicPenguin%22&FORM=HPQUIZ","wp":true,"hsh":"9c215e811683cc41760e5201d53a81ef","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250425","fullstartdate":"202504252200","enddate":"20250426","url":"/th?id=OHR.BrucePeninsula_DE-DE2577994189_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.BrucePeninsula_DE-DE2577994189","copyright":"Indian Head Cove, Bruce-Peninsula-Nationalpark, Ontario, Kanada (169 Maurice Prokaziuk/Getty Images) (169 Maurice Prokaziuk/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Bruce-Peninsula-Nationalpark+Kanada&form=hpcapt&filters=HpDate%3a%2220250425_2200%22","title":"Klippen, H246hlen und klares Wasser","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250425_BrucePeninsula%22&FORM=HPQUIZ","wp":true,"hsh":"93abe3c5f425c3c041f880b8d1eab3a1","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250426","fullstartdate":"202504262200","enddate":"20250427","url":"/th?id=OHR.LuebeckHouses_DE-DE5661377255_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.LuebeckHouses_DE-DE5661377255","copyright":"Vogelperspektive auf Giebelh228user, Gro223e Petersgrube, L252beck, Schleswig-Holstein (169 H & D ZIELSKE/Image Professionals GmbH/Alamy Stock Foto)","copyrightlink":"https://www.bing.com/search?q=Gro%C3%9Fe+Petersgrube+Luebeck&form=hpcapt&filters=HpDate%3a%2220250426_2200%22","title":"Mauern, die Geschichten erz228hlen","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250426_LuebeckHouses%22&FORM=HPQUIZ","wp":true,"hsh":"3cf2b568addc8cf9973ed1ded7fef0b1","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250427","fullstartdate":"202504272200","enddate":"20250428","url":"/th?id=OHR.OrangeImpala_DE-DE8059561226_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.OrangeImpala_DE-DE8059561226","copyright":"Impala im Moremi-Wildreservat, Botswana (169 Paul Souders/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Impalas&form=hpcapt&filters=HpDate%3a%2220250427_2200%22","title":"Wachsamer Anpassungsk252nstler","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250427_OrangeImpala%22&FORM=HPQUIZ","wp":true,"hsh":"dbb988b6a962acb289dee8ca1bf280b9","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250428","fullstartdate":"202504282200","enddate":"20250429","url":"/th?id=OHR.GardensVillandry_DE-DE3270965160_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.GardensVillandry_DE-DE3270965160","copyright":"Ch226teau de Villandry, Loiretal, Frankreich (169 Mint Images/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Chateau+de+Villandry+Frankreich&form=hpcapt&filters=HpDate%3a%2220250428_2200%22","title":"Geometrie in Bl252te","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250428_GardensVillandry%22&FORM=HPQUIZ","wp":true,"hsh":"005d4395f03bbbc428633b0bac51f270","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250429","fullstartdate":"202504292200","enddate":"20250430","url":"/th?id=OHR.ColtraneBand_DE-DE0172172574_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.ColtraneBand_DE-DE0172172574","copyright":"Jazz-Saxophonist John Coltrane und Band bei einem Auftritt 1961 in London, England (169 Popperfoto/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Internationaler+Tag+des+Jazz&form=hpcapt&filters=HpDate%3a%2220250429_2200%22","title":"Jazz ist die Musik der Seele","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250429_ColtraneBand%22&FORM=HPQUIZ","wp":false,"hsh":"4a6c722422293a03ee88114ad8ae95ad","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250430","fullstartdate":"202504302200","enddate":"20250501","url":"/th?id=OHR.PinkPlumeria_DE-DE1954010737_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.PinkPlumeria_DE-DE1954010737","copyright":"Plumeria-Blumen, Hawaii, USA (169 Miranda Jans/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Lei+Day+Feiertag&form=hpcapt&filters=HpDate%3a%2220250430_2200%22","title":"Aloha!","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250430_PinkPlumeria%22&FORM=HPQUIZ","wp":true,"hsh":"68fbc9d63b06e81029a281d322c201cb","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250501","fullstartdate":"202505012200","enddate":"20250502","url":"/th?id=OHR.BrazilHeron_DE-DE1974794289_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.BrazilHeron_DE-DE1974794289","copyright":"Mangrovereiher auf einer Victoria-Seerose, Pantanal, Brasilien (169 Gerald Corsi/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Mangrovereiher&form=hpcapt&filters=HpDate%3a%2220250501_2200%22","title":"Alleine segeln","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250501_BrazilHeron%22&FORM=HPQUIZ","wp":true,"hsh":"5d4689d54b0a1c78afcf80596e9bc022","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250502","fullstartdate":"202505022200","enddate":"20250503","url":"/th?id=OHR.SchlossMoritzburg_DE-DE9218601077_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.SchlossMoritzburg_DE-DE9218601077","copyright":"Schloss Moritzburg bei Dresden, Sachsen (169 Hans-Peter Szyszka/Huber/eStock Photo)","copyrightlink":"https://www.bing.com/search?q=Schloss+Moritzburg+Sachsen&form=hpcapt&filters=HpDate%3a%2220250502_2200%22","title":"Wie im M228rchen","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250502_SchlossMoritzburg%22&FORM=HPQUIZ","wp":true,"hsh":"e7d781f882431c59d65e7d6955e57101","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250503","fullstartdate":"202505032200","enddate":"20250504","url":"/th?id=OHR.SevilleNaboo_DE-DE9420581107_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.SevilleNaboo_DE-DE9420581107","copyright":"Plaza de Espa241a, Sevilla, Spanien (169 Horia Merla/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Star+Wars+Day&form=hpcapt&filters=HpDate%3a%2220250503_2200%22","title":"Willkommen auf dem Planeten Naboo!","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250503_SevilleNaboo%22&FORM=HPQUIZ","wp":true,"hsh":"cdea9e782e08a0437042142cfe327fa7","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250504","fullstartdate":"202505042200","enddate":"20250505","url":"/th?id=OHR.YohoNP_DE-DE0247251687_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.YohoNP_DE-DE0247251687","copyright":"Mount Burgess und Emerald Lake im Yoho-Nationalpark, British Columbia, Kanada (169 Feng Wei Photography/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Yoho-Nationalpark&form=hpcapt&filters=HpDate%3a%2220250504_2200%22","title":"Fossilien, Wasserf228lle und Waldwege","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250504_YohoNP%22&FORM=HPQUIZ","wp":true,"hsh":"d6e4b9dda3f8f008c05da86f07427648","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250505","fullstartdate":"202505052200","enddate":"20250506","url":"/th?id=OHR.FlyoverNamibia_DE-DE0196935378_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.FlyoverNamibia_DE-DE0196935378","copyright":"Ein Ultraleichtflugzeug fliegt 252ber die W252ste Namibias (169 Burt Johnson/Alamy)","copyrightlink":"https://www.bing.com/search?q=Ultraleichtflugzeug&form=hpcapt&filters=HpDate%3a%2220250505_2200%22","title":"Kein gew246hnlicher W252stentrip","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250505_FlyoverNamibia%22&FORM=HPQUIZ","wp":true,"hsh":"8a3a16b99cd30da6eec5e783c023cf85","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250506","fullstartdate":"202505062200","enddate":"20250507","url":"/th?id=OHR.DunluceIreland_DE-DE2678397911_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.DunluceIreland_DE-DE2678397911","copyright":"Dunluce Castle, Grafschaft Antrim, Nordirland (169 DieterMeyrl/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Dunluce+Castle&form=hpcapt&filters=HpDate%3a%2220250506_2200%22","title":"Mystische Mauern","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250506_DunluceIreland%22&FORM=HPQUIZ","wp":true,"hsh":"42df1e2dbe747822a712f5ffa09cf1ac","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250507","fullstartdate":"202505072200","enddate":"20250508","url":"/th?id=OHR.RhyoliteDonkeys_DE-DE0880172671_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.RhyoliteDonkeys_DE-DE0880172671","copyright":"Esel in einem Tal bei Rhyolite, Nevada, USA (169 Moelyn Photos/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Esel&form=hpcapt&filters=HpDate%3a%2220250507_2200%22","title":"Von wegen faul","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250507_RhyoliteDonkeys%22&FORM=HPQUIZ","wp":true,"hsh":"57c2ea6b09f4914cd11397bb92b2a66d","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250508","fullstartdate":"202505082200","enddate":"20250509","url":"/th?id=OHR.CuteChameleon_DE-DE1145473262_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.CuteChameleon_DE-DE1145473262","copyright":"Gew246hnliches Cham228leon (169 Photostock-Israel/SPL/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Gew%C3%B6hnliches+Cham%C3%A4leon&form=hpcapt&filters=HpDate%3a%2220250508_2200%22","title":"Der Meister der Tarnung","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250508_CuteChameleon%22&FORM=HPQUIZ","wp":true,"hsh":"5cd540cbafa895ea0f7fd1515b9112d1","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250509","fullstartdate":"202505092200","enddate":"20250510","url":"/th?id=OHR.HeidelbergSpring_DE-DE1255336849_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.HeidelbergSpring_DE-DE1255336849","copyright":"Blick auf Heidelberg und das Heidelberger Schloss im Fr252hling, Baden-W252rttemberg (169 anyaivanova/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Heidelberg&form=hpcapt&filters=HpDate%3a%2220250509_2200%22","title":"Malerische Idylle","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250509_HeidelbergSpring%22&FORM=HPQUIZ","wp":true,"hsh":"4d2c8230a849efaa220f2b9de43b2af7","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250510","fullstartdate":"202505102200","enddate":"20250511","url":"/th?id=OHR.LeopardMother_DE-DE4781516786_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.LeopardMother_DE-DE4781516786","copyright":"Leopardin leckt ihr Junges, Jao Reservat, Botswana (169 Suzi Eszterhas/Minden Pictures)","copyrightlink":"https://www.bing.com/search?q=Muttertag&form=hpcapt&filters=HpDate%3a%2220250510_2200%22","title":"Tierische Mutterliebe","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250510_LeopardMother%22&FORM=HPQUIZ","wp":true,"hsh":"f05fe69f9d899f2535647eddaca255d1","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250511","fullstartdate":"202505112200","enddate":"20250512","url":"/th?id=OHR.IrisGarden_DE-DE8196648954_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.IrisGarden_DE-DE8196648954","copyright":"Irisgarten in Tokio, Japan (169 M.Arai/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Schwertlilien&form=hpcapt&filters=HpDate%3a%2220250511_2200%22","title":"Violettes Bl252tenmeer","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250511_IrisGarden%22&FORM=HPQUIZ","wp":true,"hsh":"72d8809c19da035af49f1d7a1c5c5151","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250512","fullstartdate":"202505122200","enddate":"20250513","url":"/th?id=OHR.TorresChile_DE-DE8890780027_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.TorresChile_DE-DE8890780027","copyright":"Nationalpark Torres del Paine, Patagonien, Chile (169 Marco Bottigelli/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Nationalpark+Torres+del+Paine+&form=hpcapt&filters=HpDate%3a%2220250512_2200%22","title":"Magische Naturkulisse","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250512_TorresChile%22&FORM=HPQUIZ","wp":true,"hsh":"f43ce1c7acdf69a61333275d46e5ece9","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250513","fullstartdate":"202505132200","enddate":"20250514","url":"/th?id=OHR.SardiniaFlavia_DE-DE3762608321_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.SardiniaFlavia_DE-DE3762608321","copyright":"Porto Flavia, Sulcis-Iglesiente, Sardinien, Italien (169 Francesco Riccardo Iacomino/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Porto+Flavia+Seehafen&form=hpcapt&filters=HpDate%3a%2220250513_2200%22","title":"Ein gewagtes Projekt","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250513_SardiniaFlavia%22&FORM=HPQUIZ","wp":true,"hsh":"8605ee2da643a8369cacf9a179d022f0","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250514","fullstartdate":"202505142200","enddate":"20250515","url":"/th?id=OHR.LondonParliament_DE-DE1178909686_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.LondonParliament_DE-DE1178909686","copyright":"Big Ben und Westminster-Palast, London, England (169 Puthipong Worasaran/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Der+Big+Ben+in+London&form=hpcapt&filters=HpDate%3a%2220250514_2200%22","title":"Geschichtstr228chtige Kulisse","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250514_LondonParliament%22&FORM=HPQUIZ","wp":true,"hsh":"db86a77852514c1d6b97b0d2c979b051","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250515","fullstartdate":"202505152200","enddate":"20250516","url":"/th?id=OHR.GreenMacaw_DE-DE4297947779_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.GreenMacaw_DE-DE4297947779","copyright":"Bechsteinara, Mexiko (169 Ondrej Prosicky/Shutterstock)","copyrightlink":"https://www.bing.com/search?q=Bechsteinara&form=hpcapt&filters=HpDate%3a%2220250515_2200%22","title":"Die Vielfalt der Natur","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250515_GreenMacaw%22&FORM=HPQUIZ","wp":true,"hsh":"082173097a97ef5335761cca1023db34","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250516","fullstartdate":"202505162200","enddate":"20250517","url":"/th?id=OHR.VeniceLagoon_DE-DE3294862125_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.VeniceLagoon_DE-DE3294862125","copyright":"Delta in der Lagune von Venedig, Italien (169 Dimitri Weber/Amazing Aerial Agency)","copyrightlink":"https://www.bing.com/search?q=Lagune+von+Venedig&form=hpcapt&filters=HpDate%3a%2220250516_2200%22","title":"Die venezianische 8222Dolce Vita8220","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250516_VeniceLagoon%22&FORM=HPQUIZ","wp":true,"hsh":"93e283e28cac97070fdf9dddcb71d3b9","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250517","fullstartdate":"202505172200","enddate":"20250518","url":"/th?id=OHR.BerlinHistoryMuseum_DE-DE3052163032_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.BerlinHistoryMuseum_DE-DE3052163032","copyright":"Pei-Bau des Deutschen Historischen Museums in Berlin (169 Westend61/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Internationaler+Museumstag&form=hpcapt&filters=HpDate%3a%2220250517_2200%22","title":"Auf ins Museum!","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250517_BerlinHistoryMuseum%22&FORM=HPQUIZ","wp":true,"hsh":"6366e108f1232cb0b1c5c71036d16d79","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250518","fullstartdate":"202505182200","enddate":"20250519","url":"/th?id=OHR.MountHamilton_DE-DE9789117728_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.MountHamilton_DE-DE9789117728","copyright":"Mount Hamilton, San Francisco Bay Area, Kalifornien, USA (169 Jeffrey Lewis/TANDEM Stills + Motion)","copyrightlink":"https://www.bing.com/search?q=Mount+Hamilton+San+Francisco+Bay+Area+Kalifornien&form=hpcapt&filters=HpDate%3a%2220250518_2200%22","title":"Kreuz und quer durch Kalifornien","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250518_MountHamilton%22&FORM=HPQUIZ","wp":true,"hsh":"5bac85aea213f6cfb9520a7bbdd0a9fa","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250519","fullstartdate":"202505192200","enddate":"20250520","url":"/th?id=OHR.HoneyBeeLavender_DE-DE5467752918_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.HoneyBeeLavender_DE-DE5467752918","copyright":"Honigbiene auf Lavendelbl252te (169 Anthony Brown/Alamy)","copyrightlink":"https://www.bing.com/search?q=Weltbienentag&form=hpcapt&filters=HpDate%3a%2220250519_2200%22","title":"Klein, aber von gro223er Bedeutung","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250519_HoneyBeeLavender%22&FORM=HPQUIZ","wp":true,"hsh":"9728421905df95b1fff8ac11f96ac1a5","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250520","fullstartdate":"202505202200","enddate":"20250521","url":"/th?id=OHR.SongyangTeaGarden_DE-DE9062718883_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.SongyangTeaGarden_DE-DE9062718883","copyright":"Teegarten im Dorf Yangjiatang, Kreis Songyang, China (169 feng xu/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Internationaler+Tag+des+Tees&form=hpcapt&filters=HpDate%3a%2220250520_2200%22","title":"Die Kunst der Entspannung","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250520_SongyangTeaGarden%22&FORM=HPQUIZ","wp":true,"hsh":"b62db518edf676a9a1673a9f8df2e18b","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250521","fullstartdate":"202505212200","enddate":"20250522","url":"/th?id=OHR.BaobabAvenue_DE-DE3139251925_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.BaobabAvenue_DE-DE3139251925","copyright":"Affenbrotb228ume bei Sonnenuntergang, Baobab-Allee, Madagaskar (169 Framalicious/Shutterstock)","copyrightlink":"https://www.bing.com/search?q=Internationaler+Tag+der+Biologischen+Vielfalt&form=hpcapt&filters=HpDate%3a%2220250521_2200%22","title":"Majest228tische Riesen der Natur","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250521_BaobabAvenue%22&FORM=HPQUIZ","wp":true,"hsh":"d0966113d1be4c45cf1c062e75d3ebbb","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250522","fullstartdate":"202505222200","enddate":"20250523","url":"/th?id=OHR.ButterflyTurtle_DE-DE3016646216_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.ButterflyTurtle_DE-DE3016646216","copyright":"Julia-Falter auf der Nase einer Terekay-Schienenschildkr246te, Amazonasgebiet, Ecuador (169 Westend61/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Welt-Schildkr%C3%B6ten-Tag&form=hpcapt&filters=HpDate%3a%2220250522_2200%22","title":"Intelligente Anpassungsk252nstler","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250522_ButterflyTurtle%22&FORM=HPQUIZ","wp":true,"hsh":"7c2d9ab0b1964f3f28911b92e7becc74","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250523","fullstartdate":"202505232200","enddate":"20250524","url":"/th?id=OHR.JotunheimenPark_DE-DE8444693160_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.JotunheimenPark_DE-DE8444693160","copyright":"Jotunheimen-Nationalpark in Norwegen (169 Marisa Estivill/Shutterstock)","copyrightlink":"https://www.bing.com/search?q=Europ%C3%A4ischer+Tag+der+Parke&form=hpcapt&filters=HpDate%3a%2220250523_2200%22","title":"Die wilde Seite des Nordens","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250523_JotunheimenPark%22&FORM=HPQUIZ","wp":true,"hsh":"8a0c559c1a6c2a90cfffc2d6cfdc42e0","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250524","fullstartdate":"202505242200","enddate":"20250525","url":"/th?id=OHR.ButchartFlowers_DE-DE6034854764_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.ButchartFlowers_DE-DE6034854764","copyright":"Butchart Gardens in Brentwood Bay, British Columbia, Kanada (169 2009fotofriends/Shutterstock)","copyrightlink":"https://www.bing.com/search?q=Butchart+Gardens&form=hpcapt&filters=HpDate%3a%2220250524_2200%22","title":"Zauberhafte Bl252tenvielfalt","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250524_ButchartFlowers%22&FORM=HPQUIZ","wp":true,"hsh":"acaacc82806c5e491ddc21e9fe87e4d8","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250525","fullstartdate":"202505252200","enddate":"20250526","url":"/th?id=OHR.Arashiyama2025_DE-DE6569977297_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.Arashiyama2025_DE-DE6569977297","copyright":"Ein Zug f228hrt entlang des Hozugawa-Flusses in Arashiyama, Kyoto, Japan (169 Alvin Huang/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Arashiyama&form=hpcapt&filters=HpDate%3a%2220250525_2200%22","title":"Eine nostalgische Reise","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250525_Arashiyama2025%22&FORM=HPQUIZ","wp":true,"hsh":"0886a7928d2d07e4b65fd454260e1d39","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250526","fullstartdate":"202505262200","enddate":"20250527","url":"/th?id=OHR.MonaValePool_DE-DE2862421756_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.MonaValePool_DE-DE2862421756","copyright":"Mona Vale Ozean-Pool, Sydney, Australien (169 jamenpercy/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Mona+Vale+Ozean-Pool&form=hpcapt&filters=HpDate%3a%2220250526_2200%22","title":"Eine Badewanne im Meer","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250526_MonaValePool%22&FORM=HPQUIZ","wp":true,"hsh":"81bcd528603bbe01e269ef9c87c6b279","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250527","fullstartdate":"202505272200","enddate":"20250528","url":"/th?id=OHR.KelpOtter_DE-DE1256617925_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.KelpOtter_DE-DE1256617925","copyright":"Seeotter in einem Seetangbett schwimmend im Alaska Maritime National Wildlife Refuge, USA (169 Gerry Ellis/Minden Pictures)(169 Gerry Ellis/Minden Pictures)","copyrightlink":"https://www.bing.com/search?q=Otter&form=hpcapt&filters=HpDate%3a%2220250527_2200%22","title":"Begnadete Schwimmer","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250527_KelpOtter%22&FORM=HPQUIZ","wp":true,"hsh":"957f1f1abc551e77cb297eb4658c80ec","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250528","fullstartdate":"202505282200","enddate":"20250529","url":"/th?id=OHR.GoetheSchiller_DE-DE0833691040_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.GoetheSchiller_DE-DE0833691040","copyright":"Goethe-Schiller-Denkmal in Weimar, Th252ringen (169 Robert Ruidl/iStock/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Vatertag&form=hpcapt&filters=HpDate%3a%2220250528_2200%22","title":"Vaters Herz im Vers","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250528_GoetheSchiller%22&FORM=HPQUIZ","wp":true,"hsh":"eb770b5965c002ba346f53ab984a578d","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250529","fullstartdate":"202505292200","enddate":"20250530","url":"/th?id=OHR.LittlePigeonRiver_DE-DE2665002576_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.LittlePigeonRiver_DE-DE2665002576","copyright":"Little Pigeon River, Great-Smoky-Mountains-Nationalpark, Tennessee, USA (169 GreenStock/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Der+Little+Pigeon+River&form=hpcapt&filters=HpDate%3a%2220250529_2200%22","title":"Ein Fluss, der Geschichten erz228hlt","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250529_LittlePigeonRiver%22&FORM=HPQUIZ","wp":true,"hsh":"316a96d150f650d90788f2974a3dc84a","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250530","fullstartdate":"202505302200","enddate":"20250531","url":"/th?id=OHR.SwedenReserve_DE-DE3687449792_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.SwedenReserve_DE-DE3687449792","copyright":"Naturschutzgebiet Knuth246jdsmossen, Schweden (169 Sven Halling/DEEPOL/plainpicture)","copyrightlink":"https://www.bing.com/search?q=Knuthojdsmossen+Schweden&form=hpcapt&filters=HpDate%3a%2220250530_2200%22","title":"Eine urzeitliche Gletscherwelt","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250530_SwedenReserve%22&FORM=HPQUIZ","wp":true,"hsh":"7dd0d410a2042bbc04491174cc5307dc","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250531","fullstartdate":"202505312200","enddate":"20250601","url":"/th?id=OHR.GrandeTerreReef_DE-DE5368451110_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.GrandeTerreReef_DE-DE5368451110","copyright":"Barriere-Riff vor Grande Terre, Neukaledonien, Frankreich (169 Karsten Wrobel/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Welttag+der+Riffe&form=hpcapt&filters=HpDate%3a%2220250531_2200%22","title":"Unterwasserpracht","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250531_GrandeTerreReef%22&FORM=HPQUIZ","wp":true,"hsh":"3a39ca38df6d3509c098b24335ce0ab7","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250601","fullstartdate":"202506012200","enddate":"20250602","url":"/th?id=OHR.ChickAhnepark_DE-DE9261263631_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.ChickAhnepark_DE-DE9261263631","copyright":"G228nsek252ken auf einer Wiese im Ahnepark, Vellmar, Hessen (169 Gerhard Hagen/Getty Images)","copyrightlink":"https://www.bing.com/search?q=G%C3%A4nse+Deutschland&form=hpcapt&filters=HpDate%3a%2220250601_2200%22","title":"Niedliche Begegnung","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250601_ChickAhnepark%22&FORM=HPQUIZ","wp":true,"hsh":"316e08e8c00380ff2c10c0c206ef1f0c","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250602","fullstartdate":"202506022200","enddate":"20250603","url":"/th?id=OHR.BicyclesUtrecht_DE-DE4256517633_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.BicyclesUtrecht_DE-DE4256517633","copyright":"Fahrr228der auf einer Br252cke in Utrecht, Niederlande (169 George Pachantouris/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Weltfahrradtag&form=hpcapt&filters=HpDate%3a%2220250602_2200%22","title":"Zwischen Grachten und Fahrr228dern","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250602_BicyclesUtrecht%22&FORM=HPQUIZ","wp":true,"hsh":"3cd2022175f2084c0d9db287185e4f85","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250603","fullstartdate":"202506032200","enddate":"20250604","url":"/th?id=OHR.CalaLuna_DE-DE8318114983_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.CalaLuna_DE-DE8318114983","copyright":"Strand Cala Luna, Sardinien, Italien (169 guenterguni/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Sardinien&form=hpcapt&filters=HpDate%3a%2220250603_2200%22","title":"Lebendige Blaut246ne, klare Ansichten","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250603_CalaLuna%22&FORM=HPQUIZ","wp":true,"hsh":"4a7cd18f7144f96a982a598585f00964","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250604","fullstartdate":"202506042200","enddate":"20250605","url":"/th?id=OHR.OlivaresMural_DE-DE8057580667_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.OlivaresMural_DE-DE8057580667","copyright":"Flaschendeckel-Wandbild von Oscar Olivares in Guatire, Venezuela (169 FEDERICO PARRA/AFP via Getty Images)","copyrightlink":"https://www.bing.com/search?q=Weltumwelttag&form=hpcapt&filters=HpDate%3a%2220250604_2200%22","title":"Recycling sah noch nie so gut aus","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250604_OlivaresMural%22&FORM=HPQUIZ","wp":false,"hsh":"45834a8aac452486aa980b6f9eff2777","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250605","fullstartdate":"202506052200","enddate":"20250606","url":"/th?id=OHR.DubrovnikTwilight_DE-DE7732789552_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.DubrovnikTwilight_DE-DE7732789552","copyright":"Altstadt von Dubrovnik in Dalmatien, Kroatien (169 bluejayphoto/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Dubrovnik&form=hpcapt&filters=HpDate%3a%2220250605_2200%22","title":"Mittelalterlicher Charme","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250605_DubrovnikTwilight%22&FORM=HPQUIZ","wp":true,"hsh":"89a2bd22917c2a7834329ba0611ab3c6","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250606","fullstartdate":"202506062200","enddate":"20250607","url":"/th?id=OHR.PacificCrestTrail_DE-DE7215406983_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.PacificCrestTrail_DE-DE7215406983","copyright":"Gipfel des Pine Mountain, Angeles National Forest, Kalifornien, USA (169 Matthew Kuhns/TANDEM Stills + Motion)","copyrightlink":"https://www.bing.com/search?q=Angeles+National+Forest+Kalifornien&form=hpcapt&filters=HpDate%3a%2220250606_2200%22","title":"Auf abgelegenen Pfaden","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250606_PacificCrestTrail%22&FORM=HPQUIZ","wp":true,"hsh":"bfb1f5d4bac79ad01661ee2f70c32231","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250607","fullstartdate":"202506072200","enddate":"20250608","url":"/th?id=OHR.StellarSeaLions_DE-DE0269577220_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.StellarSeaLions_DE-DE0269577220","copyright":"Stellersche Seel246wen, Vancouver Island, British Columbia, Kanada (169 Steve Woods Photography/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Welttag+der+Ozeane&form=hpcapt&filters=HpDate%3a%2220250607_2200%22","title":"Mitteilungsfreudige Schwimmer","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250607_StellarSeaLions%22&FORM=HPQUIZ","wp":true,"hsh":"de4f9d7d0297809ce0263158785d979c","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250608","fullstartdate":"202506082200","enddate":"20250609","url":"/th?id=OHR.MillDetmold_DE-DE6095177325_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.MillDetmold_DE-DE6095177325","copyright":"M252hle im LWL-Freilichtmuseum Detmold, NRW (169 ullstein bild/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Deutscher+M%C3%BChlentag&form=hpcapt&filters=HpDate%3a%2220250608_2200%22","title":"Es klappert die M252hle","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250608_MillDetmold%22&FORM=HPQUIZ","wp":false,"hsh":"cb13a26879eeb9a407f3a89f37d70362","drk":1,"top":1,"bot":1,"hs":[],"width":0,"height":0},{"startdate":"20250608","fullstartdate":"202506082200","enddate":"20250609","url":"/th?id=OHR.MillDetmold_DE-DE7498516874_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.MillDetmold_DE-DE7498516874","copyright":"M252hle im LWL-Freilichtmuseum Detmold, NRW (169 ullstein bild/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Deutscher+M%C3%BChlentag&form=hpcapt&filters=HpDate%3a%2220250608_2200%22","title":"Wo steht diese M252hle?","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250608_MillDetmold%22&FORM=HPQUIZ","wp":false,"hsh":"1ed390df32fc293f1a8a29465dd30f69","drk":1,"top":1,"bot":1,"hs":[],"width":3840,"height":2160},{"startdate":"20250609","fullstartdate":"202506092200","enddate":"20250610","url":"/th?id=OHR.AerialEverglades_DE-DE7864298334_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp","urlbase":"/th?id=OHR.AerialEverglades_DE-DE7864298334","copyright":"Luftaufnahme des Everglades-Nationalparks, Florida, USA (169 Robert DelVecchio - OcuDrone/Getty Images)","copyrightlink":"https://www.bing.com/search?q=Everglades-Nationalpark+Florida&form=hpcapt&filters=HpDate%3a%2220250609_2200%22","title":"Ein Fluss aus Gras","quiz":"/search?q=Bing+homepage+quiz&filters=WQOskey:%22HPQuiz_20250609_AerialEverglades%22&FORM=HPQUIZ","wp":true,"hsh":"447173da4ac433de5cb4f50ba4ab7c6d","drk":1,"top":1,"bot":1,"hs":[],"width":0,"height":0}]
      '';
      download-folder = "~/Pictures/BingWallpaper/";
      hide = true;
      icon-name = "high-frame-symbolic";
      notify = false;
      override-lockscreen-blur = true;
      selected-image = "AerialEverglades_DE-DE7864298334";
      state = ''
        {"maxlongdate":202506092200,"title":"Luftaufnahme des Everglades-Nationalparks, Florida, USA","explanation":"Bing Wallpaper of the Day for 2025-06-09","copyright":"© Robert DelVecchio - OcuDrone/Getty Images","longstartdate":"202506092200","imageinfolink":"https://www.bing.com/search?q=Everglades-Nationalpark+Florida&form=hpcapt&filters=HpDate%3a%2220250609_2200%22","imageURL":"https://www.bing.com/th?id=OHR.AerialEverglades_DE-DE7864298334_UHD.jpg&qlt=100","filename":"/home/djoolz/Pictures/BingWallpaper/20250609-AerialEverglades_DE-DE7864298334_UHD.jpg","favourite":false,"width":null,"height":null,"shuffledue":0}
      '';
    };

    "org/gnome/shell/extensions/caffeine" = {
      countdown-timer = 1800;
      duration-timer = 0;
      duration-timer-list = [ 300 600 1800 ];
      indicator-position-max = 4;
      inhibit-apps = [
        "code.desktop"
        "com.vivaldi.Vivaldi.desktop"
        "org.mozilla.Thunderbird.desktop"
        "md.obsidian.Obsidian.desktop"
      ];
      nightlight-control = "always";
      restore-state = false;
      toggle-shortcut = [ "<Control><Alt>w" ];
      toggle-state = true;
      trigger-apps-mode = "on-focus";
    };

    "org/gnome/shell/extensions/clipboard-history" = {
      display-mode = 3;
      topbar-preview-size = 100;
      window-width-percentage = 0;
    };

    "org/gnome/shell/extensions/clipboard-indicator" = {
      excluded-apps = [ "Bitwarden" ];
      history-size = 50;
      move-item-first = true;
      paste-on-select = true;
      strip-text = true;
    };

    "org/gnome/shell/extensions/extension-list" = { hide-inactive = true; };

    "org/gnome/shell/extensions/paperwm" = {
      default-focus-mode = 1;
      horizontal-margin = 0;
      last-used-display-server = "Wayland";
      open-window-position = 0;
      restore-attach-modal-dialogs = "false";
      restore-edge-tiling = "true";
      restore-keybinds = ''
        {"toggle-tiled-left":{"bind":"[\\"<Super>Left\\"]","schema_id":"org.gnome.mutter.keybindings"},"toggle-tiled-right":{"bind":"[\\"<Super>Right\\"]","schema_id":"org.gnome.mutter.keybindings"},"cancel-input-capture":{"bind":"[\\"<Super><Shift>Escape\\"]","schema_id":"org.gnome.mutter.keybindings"},"restore-shortcuts":{"bind":"[\\"<Super>Escape\\"]","schema_id":"org.gnome.mutter.wayland.keybindings"},"switch-to-workspace-last":{"bind":"[\\"<Super>End\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"switch-panels":{"bind":"[\\"<Control><Alt>Tab\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"switch-group-backward":{"bind":"[\\"<Shift><Super>Above_Tab\\",\\"<Shift><Alt>Above_Tab\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"unmaximize":{"bind":"[\\"<Super>Down\\",\\"<Alt>F5\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"switch-to-workspace-1":{"bind":"[\\"<Super>Home\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"move-to-monitor-left":{"bind":"[\\"<Super><Shift>Left\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"move-to-monitor-down":{"bind":"[\\"<Super><Shift>Down\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"switch-to-workspace-left":{"bind":"[\\"<Super>Page_Up\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"switch-group":{"bind":"[\\"<Super>Above_Tab\\",\\"<Alt>Above_Tab\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"switch-panels-backward":{"bind":"[\\"<Shift><Control><Alt>Tab\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"move-to-workspace-up":{"bind":"[\\"<Control><Shift><Alt>Up\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"switch-to-workspace-right":{"bind":"[\\"<Super>Page_Down\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"move-to-workspace-down":{"bind":"[\\"<Control><Shift><Alt>Down\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"switch-applications":{"bind":"[\\"<Super>Tab\\",\\"<Alt>Tab\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"maximize":{"bind":"[\\"<Super>Up\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"move-to-monitor-right":{"bind":"[\\"<Super><Shift>Right\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"switch-applications-backward":{"bind":"[\\"<Shift><Super>Tab\\",\\"<Shift><Alt>Tab\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"move-to-monitor-up":{"bind":"[\\"<Super><Shift>Up\\"]","schema_id":"org.gnome.desktop.wm.keybindings"},"shift-overview-up":{"bind":"[\\"<Super><Alt>Up\\"]","schema_id":"org.gnome.shell.keybindings"},"shift-overview-down":{"bind":"[\\"<Super><Alt>Down\\"]","schema_id":"org.gnome.shell.keybindings"},"focus-active-notification":{"bind":"[\\"<Super>n\\"]","schema_id":"org.gnome.shell.keybindings"},"toggle-message-tray":{"bind":"[\\"<Super>v\\",\\"<Super>m\\"]","schema_id":"org.gnome.shell.keybindings"},"rotate-video-lock-static":{"bind":"[\\"<Super>o\\",\\"XF86RotationLockToggle\\"]","schema_id":"org.gnome.settings-daemon.plugins.media-keys"}}
      '';
      restore-workspaces-only-on-primary = "true";
      selection-border-radius-bottom = 0;
      selection-border-radius-top = 0;
      selection-border-size = 0;
      show-window-position-bar = true;
      show-workspace-indicator = false;
      vertical-margin = 0;
      vertical-margin-bottom = 0;
      window-gap = 2;
      winprops = [ ];
    };

    "org/gnome/shell/extensions/paperwm/workspaces" = {
      list = [
        "91534237-c2a2-44de-84a8-c2836f1a6b43"
        "7a359c16-b7d7-43b2-9ff1-f9f3ed2f987d"
        "eb0f897a-6eee-4cf5-8366-6b83637dcc6c"
        "6b109f2d-9562-42a0-96dc-901d7de6a5df"
        "a903f371-58e3-4d21-a777-557cdda6f87c"
        "85c4e5cc-422d-4079-a471-806122beeaa4"
      ];
    };

    "org/gnome/shell/extensions/paperwm/workspaces/6b109f2d-9562-42a0-96dc-901d7de6a5df" =
      {
        index = 5;
      };

    "org/gnome/shell/extensions/paperwm/workspaces/7a359c16-b7d7-43b2-9ff1-f9f3ed2f987d" =
      {
        index = 1;
      };

    "org/gnome/shell/extensions/paperwm/workspaces/85c4e5cc-422d-4079-a471-806122beeaa4" =
      {
        index = 4;
      };

    "org/gnome/shell/extensions/paperwm/workspaces/91534237-c2a2-44de-84a8-c2836f1a6b43" =
      {
        index = 0;
        show-position-bar = true;
      };

    "org/gnome/shell/extensions/paperwm/workspaces/a903f371-58e3-4d21-a777-557cdda6f87c" =
      {
        index = 3;
      };

    "org/gnome/shell/extensions/paperwm/workspaces/eb0f897a-6eee-4cf5-8366-6b83637dcc6c" =
      {
        index = 2;
      };

    "org/gnome/shell/extensions/quick-settings-tweaks" = {
      unsafe-quick-toggle-enabled = false;
    };

    "org/gnome/shell/extensions/system-monitor-next-applet" = {
      background = "#ffffff16";
      battery-batt0-color = "#f2002e";
      battery-display = false;
      battery-graph-width = 100;
      battery-hidesystem = false;
      battery-position = 9;
      battery-refresh-time = 5000;
      battery-show-menu = false;
      battery-show-text = true;
      battery-style = "digit";
      battery-time = false;
      center-display = false;
      compact-display = false;
      cpu-display = true;
      cpu-graph-width = 100;
      cpu-individual-cores = false;
      cpu-iowait-color = "#002f3d";
      cpu-nice-color = "#00a3ff";
      cpu-other-color = "#001d26";
      cpu-position = 0;
      cpu-refresh-time = 1500;
      cpu-show-menu = true;
      cpu-show-text = true;
      cpu-style = "graph";
      cpu-system-color = "#0092e6";
      cpu-user-color = "#0072b3";
      disk-display = false;
      disk-graph-width = 100;
      disk-position = 5;
      disk-read-color = "#c65000";
      disk-refresh-time = 2000;
      disk-show-menu = true;
      disk-show-text = true;
      disk-style = "graph";
      disk-usage-style = "pie";
      disk-write-color = "#ff6700";
      fan-display = false;
      fan-fan0-color = "#f2002e";
      fan-graph-width = 100;
      fan-position = 8;
      fan-refresh-time = 5000;
      fan-sensor-label = "";
      fan-show-menu = true;
      fan-show-text = true;
      fan-style = "graph";
      freq-display = false;
      freq-freq-color = "#001d26";
      freq-graph-width = 100;
      freq-position = 1;
      freq-refresh-time = 1500;
      freq-show-menu = false;
      freq-show-text = false;
      freq-style = "graph";
      gpu-display = false;
      gpu-graph-width = 100;
      gpu-memory-color = "#00ff82";
      gpu-position = 6;
      gpu-refresh-time = 5000;
      gpu-show-menu = false;
      gpu-show-text = true;
      gpu-style = "graph";
      gpu-used-color = "#00b35b";
      icon-display = true;
      memory-buffer-color = "#00ff82";
      memory-cache-color = "#aaf5d0";
      memory-display = true;
      memory-graph-width = 100;
      memory-position = 2;
      memory-program-color = "#00b35b";
      memory-refresh-time = 5000;
      memory-show-menu = true;
      memory-show-text = true;
      memory-style = "graph";
      move-clock = false;
      net-collisions-color = "#ff0000";
      net-display = true;
      net-down-color = "#fce94f";
      net-downerrors-color = "#ff6e00";
      net-graph-width = 100;
      net-position = 4;
      net-refresh-time = 1000;
      net-show-menu = true;
      net-show-text = true;
      net-speed-in-bits = false;
      net-style = "graph";
      net-up-color = "#fb74fb";
      net-uperrors-color = "#e0006e";
      rotate-labels = false;
      settings-schema-version = 1;
      show-tooltip = false;
      swap-display = false;
      swap-graph-width = 100;
      swap-position = 3;
      swap-refresh-time = 5000;
      swap-show-menu = true;
      swap-show-text = true;
      swap-style = "graph";
      swap-used-color = "#8b00c3";
      thermal-display = false;
      thermal-fahrenheit-unit = false;
      thermal-graph-width = 100;
      thermal-position = 7;
      thermal-refresh-time = 5000;
      thermal-sensor-label = "";
      thermal-show-menu = true;
      thermal-show-text = true;
      thermal-style = "graph";
      thermal-threshold = 0;
      thermal-tz0-color = "#f2002e";
      tooltip-delay-ms = 0;
    };

    "org/gnome/shell/extensions/thinkpad-battery-threshold" = {
      color-mode = true;
      indicator-mode = "ACTIVE";
      show-current-values = true;
      show-notifications = false;
    };

    "org/gnome/shell/extensions/trayIconsReloaded" = {
      applications =
        ''[{"id":"com.nextcloud.desktopclient.nextcloud.desktop"}]'';
      icon-margin-horizontal = 16;
      icon-padding-horizontal = 0;
      icons-limit = 15;
      position-weight = 1;
      tray-margin-left = 4;
      tray-position = "left";
    };

    "org/gnome/shell/extensions/vertical-workspaces" = {
      center-dash-to-ws = true;
      dash-position = 2;
      dash-position-adjust = 0;
      enable-page-shortcuts = true;
      running-dot-style = 0;
      search-fuzzy = true;
      search-view-animation = 0;
      show-ws-switcher-bg = true;
      show-wst-labels = 4;
      workspace-animation = 1;
      workspace-switcher-animation = 0;
      ws-preview-scale = 95;
      ws-thumbnail-scale-appgrid = 13;
      ws-thumbnails-position = 0;
      wst-position-adjust = 0;
    };

    "org/gnome/shell/extensions/vitals" = {
      alphabetize = false;
      hide-icons = false;
      hide-zeros = true;
      hot-sensors = [
        "_memory_usage_"
        "__network-rx_max__"
        "__network-tx_max__"
        "_processor_usage_"
        "__temperature_avg__"
        "_fan_thinkpad_fan1_"
      ];
      icon-style = 1;
      include-static-gpu-info = true;
      menu-centered = false;
      position-in-panel = 0;
      show-battery = false;
      show-gpu = false;
      show-storage = false;
      show-system = false;
    };

    "org/gnome/shell/extensions/window-list" = {
      grouping-mode = "always";
      show-on-all-monitors = true;
    };

    "org/gnome/shell/extensions/window-thumbnails" = {
      create-tmb-shortcut = [ "<Super>t" ];
      minimize-to-tmb-shortcut = [ "" ];
      remove-all-tmb-shortcut = [ "" ];
      remove-last-tmb-shortcut = [ "" ];
      schema-migrated = true;
      switch-source-next-shortcut = [ "" ];
      switch-source-prev-shortcut = [ "" ];
      toggle-visibility-shortcut = [ "" ];
    };

    "org/gnome/shell/keybindings" = {
      focus-active-notification = [ ];
      shift-overview-down = [ ];
      shift-overview-up = [ ];
      toggle-message-tray = [ ];
    };

    "org/gnome/shell/weather" = {
      window-height = 494;
      window-maximized = false;
      window-width = 439;
    };

    "org/gnome/shell/world-clocks" = { locations = [ ]; };

    "org/gnome/software" = {
      check-timestamp = mkInt64 1749541975;
      first-run = false;
      flatpak-purge-timestamp = mkInt64 1749544531;
    };

    "org/gnome/tweaks" = { show-extensions-notice = false; };

    "org/gtk/gtk4/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = true;
      sidebar-width = 140;
      sort-column = "name";
      sort-directories-first = true;
      sort-order = "ascending";
      type-format = "category";
      view-type = "list";
      window-size = mkTuple [ 1910 342 ];
    };

    "org/gtk/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sidebar-width = 171;
      sort-column = "name";
      sort-directories-first = false;
      sort-order = "descending";
      type-format = "category";
      window-position = mkTuple [ 26 23 ];
      window-size = mkTuple [ 1231 881 ];
    };

    "org/virt-manager/virt-manager" = {
      manager-window-height = 1011;
      manager-window-width = 800;
      xmleditor-enabled = true;
    };

    "org/virt-manager/virt-manager/confirm" = {
      forcepoweroff = true;
      removedev = true;
      unapplied-dev = true;
    };

    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };

    "org/virt-manager/virt-manager/conns/qemu:system" = {
      window-size = mkTuple [ 800 1011 ];
    };

    "org/virt-manager/virt-manager/details" = { show-toolbar = true; };

    "org/virt-manager/virt-manager/new-vm" = { graphics-type = "system"; };

    "org/virt-manager/virt-manager/paths" = {
      image-default =
        "/home/djoolz/Documents/13_virtual_machines/homeassistant";
    };

    "org/virt-manager/virt-manager/stats" = {
      enable-disk-poll = true;
      enable-memory-poll = true;
      enable-net-poll = true;
    };

    "org/virt-manager/virt-manager/vmlist-fields" = {
      disk-usage = true;
      memory-usage = true;
      network-traffic = true;
    };

    "org/virt-manager/virt-manager/vms/13701bc1e4104b1698b343bd75538f8c" = {
      autoconnect = 1;
      vm-window-size = mkTuple [ 1280 1011 ];
    };

    "org/virt-manager/virt-manager/vms/9177130260504176b1e5a0256f39228a" = {
      autoconnect = 1;
      vm-window-size = mkTuple [ 1299 1011 ];
    };

    "org/virt-manager/virt-manager/vms/a3a88fa58fe94d0aaa9e0959b2f11549" = {
      autoconnect = 1;
      vm-window-size = mkTuple [ 1299 842 ];
    };

    "org/virt-manager/virt-manager/vms/bc6cc2a43e5644ee8f29dabe42d8cba9" = {
      autoconnect = 1;
      vm-window-size = mkTuple [ 1280 1011 ];
    };

  };
}
