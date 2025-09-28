{ config, pkgs, ... }: {
  # If you want to use modules from other flakes (such as nixos-hardware):
  # inputs.hardware.nixosModules.common-cpu-amd
  # inputs.hardware.nixosModules.common-ssd

  # Enable Blueteeth
  # hardware.bluetooth = {
  #   enable = true;
  #   powerOnBoot = false;
  #   };

  ########################### Graphics and Video ###########################
  # Graphics drivers https://nixos.wiki/wiki/Accelerated_Video_Playback
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libvdpau-va-gl
    ];
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  }; # Force intel-media-driver

  # nixpkgs.config.cudaSupport = true; # Enable CUDA support globally. 

  ########################### Printing ############################
  # Enable CUPS to print documents.
  services.printing.enable = true;

  ########################### Audio ############################
  # Enable sound with pipewire.
  services.pulseaudio = {
    enable = false;
    # support32Bit = true; # Needed for steam
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  ########################### Fingerprint Reader ############################
  # Enable the fprintd fingerprint reader daemon.
  # Start the driver at boot
  # systemd.services.fprintd = {
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig.Type = "simple";
  # };

  ## Doesn't work, there are no drivers for my version of a fingerprint reader,
  # https://wiki.nixos.org/wiki/Fingerprint_scanner
  # services.fprintd = {
  #   enable = true;
  #   # If simply enabling fprintd doesn't work, try enabling the driver
  #   tod = {
  #     enable = true;
  #     driver = pkgs.libfprint-2-tod1-goodix; # Goodix driver module
  #     # driver = pkgs.libfprint-2-tod1-elan; # Elan(04f3:0c4b) driver
  #     # driver = pkgs.libfprint-2-tod1-vfs0090; # (Marked as broken as of 2025/04/23!) driver for 2016 ThinkPads
  #     # driver = pkgs.libfprint-2-tod1-goodix-550a; # Goodix 550a driver (from Lenovo)

  #     # however for focaltech 2808:a658, use fprintd with overidden package (without tod)
  #     # services.fprintd.package = pkgs.fprintd.override {
  #     #   libfprint = pkgs.libfprint-focaltech-2808-a658;
  #     # };
  #   };
  # };
  ############################ Trackpoint ############################
  hardware.trackpoint = {
    enable = true;
    device =
      "TPPS/2 IBM TrackPoint"; # Options: "ETPS/2 Elantech TrackPoint|Elantech PS/2 TrackPoint|TPPS/2 IBM TrackPoint|DualPoint Stick|Synaptics Inc. Composite TouchPad / TrackPoint|ThinkPad USB Keyboard with TrackPoint|USB Trackpoint pointing device|Composite TouchPad / TrackPoint|${cfg.device}"

  };

  ########################### Touchpad ############################
  # Enable touchpad support (enabled default in most desktopManager).
  # https://nixos.org/manual/nixos/stable/options
  services.libinput = {
    enable = true;
    # disabling mouse acceleration
    mouse = { accelProfile = "flat"; };
    # disabling touchpad acceleration
    touchpad = { accelProfile = "flat"; };
  };

}
