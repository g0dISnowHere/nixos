{ config, pkgs, ... }: {
  # KDE Plasma Desktop Environment
  # Provides KDE Plasma 6 with SDDM display manager
  # Reference: https://wiki.nixos.org/wiki/KDE
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [
      "modesetting"
    ]; # https://nixos.org/manual/nixos/stable/#sec-x11--graphics-cards-intel
    # Configure keymap in X11.
    xkb = { layout = "de"; };
  };

  # Enable plasma 6 Desktop Environment.
  services.desktopManager.plasma6.enable = true;

  # Enable a displaymanager.
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true; # # TODO find a better way to enable wayland.
    };
  };
}
