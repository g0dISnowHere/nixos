{ config, ... }: {
  # Allow ICMP (ping) from the 192.168.3.0/24 subnet
  # This module adds nftables rules to allow incoming echo requests
  # and outgoing echo replies for the specified subnet.
  # This is necessary because networking.firewall.allowedICMPTypes does not
  # support source IP filtering.

  networking.nftables.tables."icmp-lan" = {
    family = "inet";
    content = ''
      chain icmp-input {
        type filter hook input priority filter; policy drop;
        # Allow ICMP echo requests from 192.168.3.0/24
        ip saddr 192.168.3.0/24 icmp type echo-request accept
      }

      chain icmp-output {
        type filter hook output priority filter; policy drop;
        # Allow ICMP echo replies to 192.168.3.0/24
        ip daddr 192.168.3.0/24 icmp type echo-reply accept
      }
    '';
  };
}
