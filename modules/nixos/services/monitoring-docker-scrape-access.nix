{ lib, ... }:
let
  dockerIngressCidrs =
    [ "172.17.0.0/16" "172.30.0.0/16" "172.31.0.0/16" "172.32.0.0/16" ];
  dockerIngressInterfaces = [ "docker0" "br-*" ];
in {
  services.prometheus.exporters = {
    node.listenAddress = lib.mkForce "0.0.0.0";
    systemd.listenAddress = lib.mkForce "0.0.0.0";
  };

  networking.firewall = {
    extraInputRules = lib.mkAfter ''
      ip saddr { ${
        lib.concatStringsSep ", " dockerIngressCidrs
      } } tcp dport { 9100, 9558 } accept comment "allow Docker monitoring stack to reach host exporters"
      iifname { ${
        lib.concatStringsSep ", "
        (map (iface: ''"${iface}"'') dockerIngressInterfaces)
      } } tcp dport { 9100, 9558 } accept comment "allow Docker bridge interfaces to reach host exporters"
    '';

    extraCommands = lib.mkAfter ''
      ${lib.concatMapStringsSep "\n" (cidr: ''
        iptables -C nixos-fw -s ${cidr} -p tcp -m multiport --dports 9100,9558 -j nixos-fw-accept 2>/dev/null \
          || iptables -I nixos-fw 3 -s ${cidr} -p tcp -m multiport --dports 9100,9558 -j nixos-fw-accept
      '') dockerIngressCidrs}
    '';

    extraStopCommands = lib.mkAfter ''
      ${lib.concatMapStringsSep "\n" (cidr: ''
        iptables -D nixos-fw -s ${cidr} -p tcp -m multiport --dports 9100,9558 -j nixos-fw-accept 2>/dev/null || true
      '') dockerIngressCidrs}
    '';
  };
}
