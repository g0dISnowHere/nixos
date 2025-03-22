{
  # Bootloader.
  boot = {

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    #   grub = {
    #     enable = true;
    #     device = "/dev/sda";
    #     useOSProber = true;
    #     };
    };

    # Set resume device to enable hibernating.
    resumeDevice = "/dev/disk/by-label/swap";
    };
}