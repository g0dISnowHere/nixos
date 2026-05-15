{ lib, ... }: {
  services.prometheus.exporters = {
    node.listenAddress = lib.mkForce "0.0.0.0";
    systemd.listenAddress = lib.mkForce "0.0.0.0";
  };
  # Need to open ports [9100 9558] in host firewall.nix.
  # Also allow Docker bridge input rule for exporter scrape in host firewall.nix.
}
