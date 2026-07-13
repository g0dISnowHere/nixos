{ lib, pkgs, ... }: {
  # Shared Desktop Infrastructure
  # Imported by all desktop environment modules (gnome.nix, plasma.nix, etc.)
  # Provides: audio and X11 base
  # Host files import optional capabilities like printing, Bluetooth, and service discovery explicitly

  # X11 windowing system base
  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "modesetting" ];
      xkb = {
        layout = "de";
      };
    };

    # Audio (PipeWire)
    # Keep desktop audio available by default, but allow machine-specific modules
    # to override these values for low-latency setups.
    pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      alsa.support32Bit = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
      jack.enable = lib.mkDefault false;
    };

  };

  fonts.packages = with pkgs; [
    cantarell-fonts
    noto-fonts
    noto-fonts-color-emoji
  ];

  fonts.fontconfig = {
    defaultFonts = {
      sansSerif = [
        "Noto Sans"
        "Cantarell"
      ];
      serif = [ "Noto Serif" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  # Authorization framework used by desktop-integrated system services.
  security.polkit.enable = true;

  security.rtkit.enable = lib.mkDefault true;

}
