_: {
  networking.firewall = {
    # Collector debug and GPU metrics remain Tailscale-only.
    interfaces.tailscale0.allowedTCPPorts = [
      8080
      12345
      9400
    ];
  };
}
