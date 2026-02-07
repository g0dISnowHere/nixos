{ config, pkgs, ... }: {
  # Flatpak Support with Application List
  # Provides sandboxed application distribution via Flatpak
  # Reference: https://github.com/gmodena/nix-flatpak

  services.flatpak = {
    enable = true;

    # Optional: Add custom Flathub beta repository
    # remotes = [{
    #   name = "flathub-beta";
    #   location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
    # }];

    packages = [
      # 3D and CAD
      "org.blender.Blender"
      "org.freecad.FreeCAD"
      "org.kicad.KiCad"
      "org.librecad.librecad"
      "org.openscad.OpenSCAD"

      # Development Tools
      "com.github.tchx84.Flatseal" # Flatpak permissions manager
      "io.dbeaver.DBeaverCommunity" # Database client
      "io.github.Omniaevo.mqtt5-explorer" # MQTT explorer
      "com.freerdp.FreeRDP" # Remote Desktop Protocol client
      "com.rustdesk.RustDesk" # RustDesk remote desktop

      # Communication
      "org.mozilla.Thunderbird" # Email client
      "org.signal.Signal" # Signal messenger
      "com.spotify.Client" # Spotify

      # Utilities
      "io.github.flattool.Warehouse" # Flatpak package manager
      "io.github.giantpinkrobots.flatsweep" # Unused dependency cleaner
      "com.github.tchx84.Flatseal" # Permissions manager
      "page.tesk.Refine" # OpenRefine (data tool)

      # Design and 3D Printing
      "com.connorcode.mslicer" # 3D printer slicer
      "com.prusa3d.PrusaSlicer" # Prusa 3D printer slicer

      # Productivity
      "io.github.alainm23.planify" # To-do list and task planner

      # Internet and Media
      "org.mozilla.firefox" # Firefox browser
      "com.vivaldi.Vivaldi" # Vivaldi browser
      "org.gnome.Extensions" # GNOME extensions browser
      "org.gnome.PowerStats" # Power consumption monitor

      # Network Tools
      "org.nmap.Zenmap" # Network security scanner

      # Disabled by default - uncomment to enable:
      # "org.syncthing.syncthing"  # File sync
    ];

    # Auto-update Flatpak applications
    update = {
      onActivation = true;
      auto = {
        enable = true;
        onCalendar = "weekly"; # Check for updates weekly
      };
    };
  };

  # Additional fonts for Flatpak applications
  environment.systemPackages = with pkgs; [
    cantarell-fonts
    fira-code
    nerd-fonts.open-dyslexic
  ];
}
