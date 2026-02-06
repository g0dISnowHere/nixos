{ config, pkgs, ... }: {
  services = {
    # syncthing.enable = true;
    # https://github.com/gmodena/nix-flatpak
    flatpak = {
      enable = true;
      # remotes = [{
      #   name = "flathub-beta";
      #   location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      # }];
      packages = [
        # TODO Add your desired Flatpak packages here
        "com.connorcode.mslicer"
        "com.freerdp.FreeRDP"
        "com.github.tchx84.Flatseal"
        "com.prusa3d.PrusaSlicer"
        "com.rustdesk.RustDesk"
        "com.spotify.Client"
        "com.vivaldi.Vivaldi"
        "io.dbeaver.DBeaverCommunity"
        "io.github.Omniaevo.mqtt5-explorer"
        "io.github.alainm23.planify"
        "io.github.flattool.Warehouse"
        "io.github.giantpinkrobots.flatsweep"
        "org.blender.Blender"
        "org.freecad.FreeCAD"
        "org.gnome.Extensions"
        "org.gnome.PowerStats"
        "org.kicad.KiCad"
        "org.librecad.librecad"
        "org.mozilla.Thunderbird"
        "org.mozilla.firefox"
        "org.nmap.Zenmap"
        "org.openscad.OpenSCAD"
        "org.signal.Signal"
        "page.tesk.Refine"
      ];
      update = {
        onActivation = true;
        auto = {
          enable = true;
          onCalendar = "weekly"; # Default value
        };
      };
    };

  };
  home.packages = with pkgs; [
    cantarell-fonts
    fira-code
    # noto-fonts
    nerd-fonts.open-dyslexic

    libreoffice-qt
    hunspell
    hunspellDicts.de_DE
    hunspellDicts.en_US
  ];

}
