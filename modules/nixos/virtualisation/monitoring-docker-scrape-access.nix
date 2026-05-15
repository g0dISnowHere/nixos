{ lib, ... }: {
  services.prometheus.exporters = {
    node.listenAddress = lib.mkForce "0.0.0.0";
    systemd.listenAddress = lib.mkForce "0.0.0.0";
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9100 9558 ];
}
