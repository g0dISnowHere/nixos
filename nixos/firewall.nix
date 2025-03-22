{config, ...}:
{

  # Open ports in the firewall.
  # https://nixos.wiki/wiki/Firewall
  networking.firewall = {
    enable = true;
    # allowedTCPPorts = [ 24800 22000 ];
    # allowedUDPPorts = [69]; # TFTP, for flashing openwrt to fritzbox routers
    # allowedUDPPortRanges = [
    #   { from = 4000; to = 4007; }
    #   { from = 8000; to = 8010; }
    #   ];

  };
}