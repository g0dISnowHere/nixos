_: {
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
    extraConfig = ''
      serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
      terminal_input console serial
      terminal_output console serial
    '';
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];

  # Keep provider recovery consoles usable through both boot and login.
  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0"
    "systemd.ssh_auto=no"
  ];
}
