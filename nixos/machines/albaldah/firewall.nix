_: {
  networking.nftables.enable = true;

  networking.firewall = {
    # Public HTTPS ingress for reverse proxy
    allowedTCPPorts = [
      80
      443
    ];

  };
}
