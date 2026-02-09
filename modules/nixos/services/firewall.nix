{ config, ... }: {
  # Firewall Configuration with Port Rules
  # Enables firewall with nftables backend and specific port allowlists for services
  # Reference: https://nixos.wiki/wiki/Firewall

  # Enable nftables as the firewall backend
  # This provides a modern, performant firewall implementation
  networking.nftables.enable = true;

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
