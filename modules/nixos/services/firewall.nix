{ config, ... }: {
  # Firewall Configuration with Port Rules
  # Enables firewall with specific port allowlists for services
  # Includes bridge networking rules for VM networking (libvirtd)
  # Reference: https://nixos.wiki/wiki/Firewall

  networking.firewall = {
    enable = true;

    # Application-specific ports
    allowedTCPPorts = [
      22000 # Syncthing
      24800 # Barrier (KVM/mouse sharing)
    ];

    allowedUDPPorts = [
      # 41641 is handled by Tailscale module
      # 69 TFTP for flashing routers (commented by default)
    ];
  };
}
