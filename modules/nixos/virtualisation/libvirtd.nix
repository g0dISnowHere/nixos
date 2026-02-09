{ config, lib, pkgs, ... }:
let cfg = config.my.libvirt;
in {
  # Libvirtd/KVM Virtualization with Bridge Networking
  #
  # IMPORTANT: To enable bridge networking, update these interface names
  # in your machine configuration (nixos/machines/your-machine/default.nix):
  #
  #   my.libvirt = {
  #     bridgeInterface = "br0";              # Bridge interface name
  #     physicalInterface = "enp0s31f6";      # Your physical ethernet interface
  #   };
  #
  # Find your interface name with: ip link show

  config = {
    # Assertion: both interfaces must be set together
    assertions = [{
      assertion = (cfg.bridgeInterface == null && cfg.physicalInterface == null)
        || (cfg.bridgeInterface != null && cfg.physicalInterface != null);
      message = ''
        my.libvirt: Both bridgeInterface and physicalInterface must be set together, or both null.
        Example configuration in nixos/machines/your-machine/default.nix:
          my.libvirt = {
            bridgeInterface = "br0";
            physicalInterface = "enp0s31f6";
          };
      '';
    }];

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
    # For nftables to filter bridged traffic, enable bridge netfilter hooks
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      # Enable bridge netfilter so nftables can inspect bridged packets
      "net.bridge.bridge-nf-call-iptables" = 1;
      "net.bridge.bridge-nf-call-ip6tables" = 1;
      "net.bridge.bridge-nf-call-arptables" = 1;
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

    # Network configuration for bridge (when interfaces are configured)
    networking.networkmanager.unmanaged =
      lib.mkIf (cfg.bridgeInterface != null) [
        cfg.physicalInterface
        cfg.bridgeInterface
      ];

    networking.bridges = lib.mkIf (cfg.bridgeInterface != null) {
      "${cfg.bridgeInterface}".interfaces = [ cfg.physicalInterface ];
    };

    networking.interfaces = lib.mkIf (cfg.bridgeInterface != null) {
      "${cfg.bridgeInterface}".useDHCP = true;
      "${cfg.physicalInterface}".useDHCP = false;
    };

    # Firewall rules for libvirt bridge networking
    networking.firewall.trustedInterfaces =
      lib.mkIf (cfg.bridgeInterface != null) [ cfg.bridgeInterface ];

    # Define the bridge network for libvirt/virt-manager (when interfaces are configured)
    systemd.services = lib.mkIf (cfg.bridgeInterface != null) {
      libvirt-bridge-network = {
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
          if ${pkgs.libvirt}/bin/virsh net-list --all | grep -q "${cfg.bridgeInterface}"; then
            echo "Bridge network already exists"
            exit 0
          fi

          # Create network definition
          cat > /tmp/${cfg.bridgeInterface}-network.xml << EOF
          <network>
            <name>${cfg.bridgeInterface}</name>
            <forward mode='bridge'/>
            <bridge name='${cfg.bridgeInterface}'/>
          </network>
          EOF

          # Define and start the network
          ${pkgs.libvirt}/bin/virsh net-define /tmp/${cfg.bridgeInterface}-network.xml
          ${pkgs.libvirt}/bin/virsh net-start ${cfg.bridgeInterface}
          ${pkgs.libvirt}/bin/virsh net-autostart ${cfg.bridgeInterface}

          # Clean up
          rm /tmp/${cfg.bridgeInterface}-network.xml

          echo "Bridge network ${cfg.bridgeInterface} created and configured for libvirt"
        '';
        path = with pkgs; [ libvirt ];
      };
    };

    # nftables rules for libvirt bridge forwarding (when interfaces are configured)
    networking.nftables.tables."libvirt-bridge" =
      lib.mkIf (cfg.bridgeInterface != null) {
        family = "inet";
        content = ''
          chain bridge-forward {
            type filter hook forward priority filter; policy drop;
            # Allow all traffic through bridge
            iifname "${cfg.bridgeInterface}" accept
            oifname "${cfg.bridgeInterface}" accept
            # Allow bridge to communicate with physical interface
            iifname "${cfg.bridgeInterface}" oifname "${cfg.physicalInterface}" accept
            iifname "${cfg.physicalInterface}" oifname "${cfg.bridgeInterface}" accept
          }
        '';
      };
  };
}
