{ config, pkgs, ... }: {
  # Libvirtd/KVM Virtualization
  # Provides KVM/QEMU virtualization with virt-manager, SPICE USB redirection, and OVMF UEFI support
  # Reference: https://nixos.wiki/wiki/Libvirt
  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        vhostUserPackages =
          [ pkgs.virtiofsd ]; # virtiofsd is needed for vhost-user-fs
        runAsRoot = true;
        swtpm.enable = true;
        # Note: OVMF is now available by default, no need to configure packages
      };
    };
  };

  users.users.djoolz = { extraGroups = [ "libvirtd" ]; };

  # nested virtualization
  boot.extraModprobeConfig = "options kvm_intel nested=1";

  # Enable bridge kernel modules and IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.bridge.bridge-nf-call-ip6tables" = 0;
    "net.bridge.bridge-nf-call-arptables" = 0;
  };

  # Load bridge kernel modules
  boot.kernelModules = [ "bridge" "br_netfilter" ];

  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    # spice
    # spice-gtk
    # spice-protocol
    # win-virtio
    # win-spice
  ];

  services.spice-vdagentd.enable = true;

  # Network bridge configuration for Home Assistant VM
  networking = {
    # Make the fucking unmanaged.
    networkmanager.unmanaged = [ "enp0s31f6" "br0" ];

    # Create bridge for VM networking
    bridges.br0.interfaces = [ "enp0s31f6" ];

    # Configure bridge to get IP via DHCP
    interfaces.br0.useDHCP = true;

    # Ensure the physical interface has no IP (bridge takes over)
    interfaces.enp0s31f6.useDHCP = false;
  };

  # Define the bridge network for libvirt/virt-manager
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
      if ${pkgs.libvirt}/bin/virsh net-list --all | grep -q "br0"; then
        echo "Bridge network already exists"
        exit 0
      fi

      # Create network definition
      cat > /tmp/br0-network.xml << EOF
      <network>
        <name>br0</name>
        <forward mode='bridge'/>
        <bridge name='br0'/>
      </network>
      EOF

      # Define and start the network
      ${pkgs.libvirt}/bin/virsh net-define /tmp/br0-network.xml
      ${pkgs.libvirt}/bin/virsh net-start br0
      ${pkgs.libvirt}/bin/virsh net-autostart br0

      # Clean up
      rm /tmp/br0-network.xml

      echo "Bridge network br0 created and configured for libvirt"
    '';
    path = with pkgs; [ libvirt ];
  };

  # Firewall rules for libvirt bridge networking
  networking.firewall = {
    trustedInterfaces = [ "br0" ];

    extraCommands = ''
      # Allow traffic through bridge
      iptables -I FORWARD -i br0 -j ACCEPT
      iptables -I FORWARD -o br0 -j ACCEPT

      # Allow bridge to communicate with physical interface
      # CUSTOMIZE: Replace enp0s31f6 with your actual interface name
      iptables -I FORWARD -i br0 -o enp0s31f6 -j ACCEPT
      iptables -I FORWARD -i enp0s31f6 -o br0 -j ACCEPT
    '';

    extraStopCommands = ''
      # Clean up bridge rules on firewall stop
      iptables -D FORWARD -i br0 -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -o br0 -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -i br0 -o enp0s31f6 -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -i enp0s31f6 -o br0 -j ACCEPT 2>/dev/null || true
    '';
  };
}
