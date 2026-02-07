{ config, pkgs, ... }: {
  # GNOME Desktop Environment
  # Provides GNOME desktop with Wayland support and GDM login manager
  # Reference: https://wiki.nixos.org/wiki/GNOME

  # Enable the X11 windowing system
  services.xserver = {
    enable = true;
    videoDrivers = [ "modesetting" ];
    # Configure keymap in X11
    xkb = { layout = "de"; };
  };

  # Enable GNOME Desktop Environment
  services.desktopManager.gnome.enable = true;

  # Enable GDM display manager (login screen)
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
}
