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

  # Audio (PipeWire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
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
