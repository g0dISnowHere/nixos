_: {
  networking.firewall = {
    # Prometheus node exporter
    interfaces.tailscale0.allowedTCPPorts = [
      9100
      9558
    ];

    # Allow Docker bridge Prometheus scrape to host exporters
    extraInputRules = ''
      iifname { "docker0", "br-*" } tcp dport { 9100, 9558 } accept comment "allow Docker bridge Prometheus scrape to host exporters"
    '';
  };
}
