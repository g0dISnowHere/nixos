{ pkgs, lib, ... }:

{
  hardware.firmware = [ pkgs.linux-firmware ];

  # Mitigate e1000e "Hardware Unit Hang" on laptop NICs by disabling EEE + power down.
  boot.extraModprobeConfig = lib.mkAfter ''
    options e1000e EEE=0 SmartPowerDownEnable=0
  '';

  # If hangs persist, disable PCIe ASPM which can trigger link drops on e1000e.
  # boot.kernelParams = [ "pcie_aspm=off" ];
}
