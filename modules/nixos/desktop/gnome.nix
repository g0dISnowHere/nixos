{ config, pkgs, ... }: {
  # GNOME Desktop Environment
  # Provides full GNOME desktop with GDM display manager, multi-touch gestures, and GSConnect
  # Reference: https://wiki.nixos.org/wiki/GNOME
  # Enable the X11 windowing system.
  services = {

    # Enable the GNOME Desktop Environment.
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    xserver = {
      enable = true;

      # Configure keymap in X11
      xkb = {
        layout = "de";
        variant = "";
      };
    };

    touchegg.enable = true; # Enable Touchegg for multi-touch gestures

  };

  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  # Install GNOME related packages
  environment.systemPackages = with pkgs; [
    dconf-editor
    dconf2nix # https://github.com/nix-community/dconf2nix
    gnome-tweaks

    gsound # for gnome clipboard extension
    touchegg
    # gnomeExtensions.another-window-session-manager
    # gnomeExtensions.gsconnect
  ];
}
