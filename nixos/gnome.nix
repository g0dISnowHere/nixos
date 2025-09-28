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

  # Install GNOME related packages
  environment.systemPackages = with pkgs; [
    dconf-editor
    dconf2nix # https://github.com/nix-community/dconf2nix
    gnome-tweaks
    gnomeExtensions.paperwm
    gnomeExtensions.another-window-session-manager
    # Add more extensions below as needed
    # gnomeExtensions.gsconnect
  ];

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
