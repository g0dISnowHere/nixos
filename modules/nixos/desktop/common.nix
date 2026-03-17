{ config, lib, pkgs, ... }: {
  # Shared Desktop Infrastructure
  # Imported by all desktop environment modules (gnome.nix, plasma.nix, etc.)
  # Provides: audio, printing, Bluetooth, network service discovery, X11 base
  # Each DE module imports this and adds its own desktop environment + display manager

  # X11 windowing system base
  services.xserver = {
    enable = true;
    videoDrivers = [ "modesetting" ];
    xkb = { layout = "de"; };
  };

  fonts.packages = with pkgs; [
    cantarell-fonts
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontconfig = {
    defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font Mono" ];
      sansSerif = [ "Noto Sans" "Cantarell" ];
      serif = [ "Noto Serif" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  # Authorization framework used by desktop-integrated system services.
  security.polkit.enable = true;

  # Audio (PipeWire)
  # Keep desktop audio available by default, but allow machine-specific modules
  # to override these values for low-latency setups.
  security.rtkit.enable = lib.mkDefault true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    alsa.support32Bit = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
    jack.enable = lib.mkDefault false;
  };

  # Printing
  services.printing.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Network service discovery (printer auto-detection, etc.)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
