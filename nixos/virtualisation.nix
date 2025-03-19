# https://nixos.wiki/wiki/Virtualization

{pkgs, ... }:
{
  virtualisation.libvirtd = {
      enable = true;
      # Used for UEFI boot of Home Assistant OS guest image
      qemuOvmf = true;
    };
  
  virtualisation.spiceUSBRedirection.enable = true;

  environment.systemPackages = with pkgs; [
    # For virt-install
    virt-manager

    # For lsusb
    usbutils
  ];

  # Access to libvirtd
  users.users.myme = {
    extraGroups = ["libvirtd"];
  };
}