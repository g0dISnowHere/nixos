# https://nixos.wiki/wiki/Virtualization
# https://nixos.wiki/wiki/Virt-manager

{pkgs, ... }:
{
  virtualisation = {
    libvirtd = {
      enable = true;
      # Used for UEFI boot of Home Assistant OS guest image
    #   qemu.ovmf = {
    #     enable = true;
    #     };
    qemu = {
      # package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [(pkgs.OVMF.override {
          secureBoot = true;
          tpmSupport = true;
        }).fd];
      };
    };
  };
    spiceUSBRedirection.enable = true;
  };
  
  # networking = {
  #   # enable bridge networking for homeassistant in a VM
  #   defaultGateway = "10.0.0.1";
  #   bridges.br0.interfaces = ["eno1"];
  #   interfaces.br0 = {
  #     useDHCP = false;
  #     ipv4.addresses = [{
  #       "address" = "10.0.0.5";
  #       "prefixLength" = 24;
  #     }];
  #   };
  #   firewall.allowedTCPPorts = [
  #     5900
  #   ];
  # };

  # environment.systemPackages = with pkgs; [
  #   # For virt-install
  #   virt-manager

  #   # For lsusb
  #   usbutils
  # ];

  # Access to libvirtd
  users.users.djoolz = {
    extraGroups = ["libvirtd"];
  };
}