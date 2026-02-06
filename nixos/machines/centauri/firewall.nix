{ config, ... }: {

  # Open ports in the firewall.
  # https://nixos.wiki/wiki/Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      24800 # barrier
      22000 # syncthing
    ];

    allowedUDPPorts = [
      # 41641 # https://fzakaria.com/2020/09/17/tailscale-is-magic-even-more-so-with-nixos.html
      # 69 # TFTP, for flashing openwrt to fritzbox routers
    ];
    # allowedUDPPortRanges = [
    #   { from = 4000; to = 4007; }
    #   { from = 8000; to = 8010; }
    #   ];

    # Allow bridge traffic for VM networking
    trustedInterfaces = [ "br0" ];

    # Bridge networking requires these rules
    extraCommands = ''
      # Allow traffic through bridge
      iptables -I FORWARD -i br0 -j ACCEPT
      iptables -I FORWARD -o br0 -j ACCEPT

      # Allow bridge to communicate with physical interface
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
