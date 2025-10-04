{ config, pkgs, ... }:

# https://wiki.nixos.org/wiki/KDE

{
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    # Enable the GNOME Desktop Environment.
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # Configure keymap in X11
    xkb = {
      layout = "de";
      variant = "";
    };
  };

  security.rtkit.enable = true; # for gnome sound settings

  # Enable polkit for authentication
  security.polkit.enable = true;

  # Install GNOME related packages
  environment.systemPackages = with pkgs; [
    dconf-editor
    dconf2nix # https://github.com/nix-community/dconf2nix
    gnome-tweaks
    gnomeExtensions.paperwm
    gnomeExtensions.another-window-session-manager
    polkit_gnome # Authentication agent for GNOME
    # Add more extensions below as needed
    # gnomeExtensions.gsconnect
  ];

  # Start polkit authentication agent automatically
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart =
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      # lockAll = true; # prevents overriding
      settings = {
        "org/gnome/desktop/interface" = {
          # clock-show-weekday = true;
        };
      };
    }];
  };

}
