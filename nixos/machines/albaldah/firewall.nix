_: {
  networking.nftables.enable = true;

  networking.firewall = {
    # Public HTTPS ingress for reverse proxy
    allowedTCPPorts = [
      80
      443
    ];

    # Prometheus node exporter
    interfaces.tailscale0.allowedTCPPorts = [
      9100
      9558
    ];

    # Allow Docker-origin Prometheus scrape to host exporters.
    # host.docker.internal resolves via docker0 on this host (172.17.0.1).
    extraInputRules = ''
      ip saddr 172.17.0.0/16 tcp dport { 9100, 9558 } accept comment "allow Docker bridge Prometheus scrape to host exporters"
      ip saddr 172.31.0.0/16 tcp dport { 9100, 9558 } accept comment "allow monitoring bridge Prometheus scrape to host exporters"
    '';
  };
}
