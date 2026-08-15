_: {
  networking.firewall = {
    # Tailscale-only Prometheus scrapes: node, systemd, cAdvisor, Alloy, DCGM.
    interfaces.tailscale0.allowedTCPPorts = [
      9100
      9558
      8080
      12345
      9400
    ];

    # Allow Docker bridge Prometheus scrape to host exporters.
    extraInputRules = ''
      iifname { "docker0", "br-*" } tcp dport { 9100, 9558 } accept comment "allow Docker bridge Prometheus scrape to host exporters"
    '';
  };
}
