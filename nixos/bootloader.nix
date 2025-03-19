{
  # Bootloader.
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = true;
        };
      };

    # Set resume device to enable hibernating.
    resumeDevice = "/dev/disk/by-label/swap";
    };
}