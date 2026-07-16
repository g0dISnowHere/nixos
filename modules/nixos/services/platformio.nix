{ pkgs, ... }: {
  services.udev.packages = with pkgs; [
    platformio-core.udev
    openocd
  ];

  services.udev.extraRules = ''
    # Allow the active local user session to access common USB serial devices.
    SUBSYSTEM=="tty", KERNEL=="ttyUSB[0-9]*", TAG+="uaccess"
    SUBSYSTEM=="tty", KERNEL=="ttyACM[0-9]*", TAG+="uaccess"
  '';
}
