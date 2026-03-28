{ pkgs, ... }:
let
  bridgeInterface = "br0";
  physicalInterface = "enp0s31f6";
in {
  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        vhostUserPackages = [ pkgs.virtiofsd ];
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
  };

  users.users.djoolz.extraGroups = [ "libvirtd" ];

  boot.extraModprobeConfig = "options kvm_intel nested=1";
  boot.kernelModules = [ "bridge" "br_netfilter" ];
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
    "net.bridge.bridge-nf-call-arptables" = 1;
  };

  environment.systemPackages = with pkgs; [ virt-manager virt-viewer ];

  services.spice-vdagentd.enable = true;

  networking.networkmanager.unmanaged = [ physicalInterface bridgeInterface ];

  networking.bridges = {
    "${bridgeInterface}".interfaces = [ physicalInterface ];
  };

  networking.interfaces = {
    "${bridgeInterface}".useDHCP = true;
    "${physicalInterface}".useDHCP = false;
  };

  networking.firewall.trustedInterfaces = [ bridgeInterface ];

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
      if ${pkgs.libvirt}/bin/virsh net-list --all | grep -q "${bridgeInterface}"; then
        echo "Bridge network already exists"
        exit 0
      fi

      cat > /tmp/${bridgeInterface}-network.xml << EOF
      <network>
        <name>${bridgeInterface}</name>
        <forward mode='bridge'/>
        <bridge name='${bridgeInterface}'/>
      </network>
      EOF

      ${pkgs.libvirt}/bin/virsh net-define /tmp/${bridgeInterface}-network.xml
      ${pkgs.libvirt}/bin/virsh net-start ${bridgeInterface}
      ${pkgs.libvirt}/bin/virsh net-autostart ${bridgeInterface}

      rm /tmp/${bridgeInterface}-network.xml

      echo "Bridge network ${bridgeInterface} created and configured for libvirt"
    '';
    path = with pkgs; [ libvirt ];
  };
}
