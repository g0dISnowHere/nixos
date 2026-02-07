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
      8123 # Home Assistant (if using)
    ];

    allowedUDPPorts = [
      # 41641 is handled by Tailscale module
      # 69 TFTP for flashing routers (commented by default)
    ];

    # Allow bridge traffic for VM networking (libvirtd)
    trustedInterfaces = [ "br0" ];

    # Bridge networking requires these iptables rules
    # Customize interface names if different (e.g., enp0s31f6 → your interface)
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
