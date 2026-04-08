{ lib, pkgs, ... }:
let
  bridgeInterface = "br0";
  physicalInterface = "enp0s25";
  bridgeMacAddress = "3c:97:0e:5b:2d:c2";
in {
  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        package = pkgs.qemu_kvm;
        vhostUserPackages = [ pkgs.virtiofsd ];
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
  };

  users.users.djoolz.extraGroups = [ "libvirtd" ];

  boot.extraModprobeConfig = lib.mkAfter ''
    options kvm_intel nested=1
    options e1000e EEE=0 SmartPowerDownEnable=0
  '';
  boot.kernelModules = [ "bridge" "br_netfilter" ];
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.bridge.bridge-nf-call-ip6tables" = 0;
    "net.bridge.bridge-nf-call-arptables" = 0;
  };

  environment.systemPackages = with pkgs; [ virt-manager virt-viewer OVMF ];

  services.spice-vdagentd.enable = true;

  networking = {
    networkmanager.unmanaged = [ physicalInterface bridgeInterface ];
    bridges = { "${bridgeInterface}".interfaces = [ physicalInterface ]; };
    interfaces = {
      "${bridgeInterface}".useDHCP = true;
      "${physicalInterface}".useDHCP = false;
    };
    # Keep the bridge MAC stable so carrier does not flap when guests start or stop.
    localCommands = ''
      ${pkgs.iproute2}/bin/ip link set ${bridgeInterface} address ${bridgeMacAddress}
    '';
  };

  systemd.services.libvirt-bridge-network = {
    description = "Create libvirt bridge network";
    after = [ "libvirtd.service" "network.target" ];
    wants = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Check if bridge network already exists
      if ${pkgs.libvirt}/bin/virsh net-list --all | grep -q "${bridgeInterface}"; then
        echo "Bridge network already exists"
        exit 0
      fi

      # Create network definition
      cat > /tmp/${bridgeInterface}-network.xml << EOF
      <network>
        <name>${bridgeInterface}</name>
        <forward mode='bridge'/>
        <bridge name='${bridgeInterface}'/>
      </network>
      EOF

      # Define and start the network
      ${pkgs.libvirt}/bin/virsh net-define /tmp/${bridgeInterface}-network.xml
      ${pkgs.libvirt}/bin/virsh net-start ${bridgeInterface}
      ${pkgs.libvirt}/bin/virsh net-autostart ${bridgeInterface}

      # Clean up
      rm /tmp/${bridgeInterface}-network.xml

      echo "Bridge network ${bridgeInterface} created and configured for libvirt"
    '';
    path = with pkgs; [ libvirt ];
  };
}
