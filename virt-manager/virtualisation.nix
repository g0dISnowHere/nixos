# https://nixos.wiki/wiki/Virtualization
# https://nixos.wiki/wiki/Virt-manager

{
  pkgs,
  config,
  ... 
}:
{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
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
  
  ## Enable nested virtualisation
  boot.extraModprobeConfig = "options kvm_intel nested=1";

  ## using dynamic address
  networking = {
    networkmanager.unmanaged = [ "enp0s25" ]; # List interfaces that should not be managed by NetworkManager. It is not capable of bridge networks. But this also breaks any other internetconnection.
    useDHCP = false;
    interfaces.enp0s25.useDHCP = true; # Use DHCP on the main interface.
    interfaces.virbr0.useDHCP = true; # Use DHCP on the bridge interface.
    bridges.virbr0.interfaces = [ "enp0s25" ];
    defaultGateway = "192.168.3.1"; # This should reflect the actual network topology
    nameservers = [ "192.168.3.1" ];

    ## Open necessary firewall ports
    firewall.allowedTCPPorts = [
      ## Homeassistant
      5900
      8123
      ## mqtt
      ## NTP
      ## DNS
      53
    ];
    };

  ## networking with static address
  # networking = {
  #   useDHCP = false;
  #   networkmanager.unmanaged = [ "enp0s25" ]; # List interfaces that should not be managed by NetworkManager. It is not capable of bridge networks. But this also breaks any other internetconnection.
  #   bridges.virbr0.interfaces = [ "enp0s25" ];
  #   interfaces.virbr0.ipv4.addresses = [{
  #     address = "192.168.3.10";
  #     prefixLength = 24;
  #     }];
  #   defaultGateway = "192.168.3.1";
  #   nameservers = [ "192.168.3.1" ];
  #   firewall.allowedTCPPorts = [
  #     5900
  #     ];
  #   };

  environment.systemPackages = with pkgs; [
    ## For virt-install
    virt-manager
    # libguestfs-with-appliance
    libvirt
    # libvirt-glib
    ## For lsusb
    usbutils
    ];

  ## Access to libvirtd
  users.users.djoolz = {
    extraGroups = ["libvirtd"];
    };
  }