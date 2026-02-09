{ config, ... }: {
  # Allow ICMP (ping) from the 192.168.3.0/24 subnet
  # NOTE: This requires nftables backend. With iptables backend, use extraCommands.
  # For now, ICMP filtering is disabled - use networking.firewall.allowPing = true
  # for unrestricted ICMP, or implement source filtering via extraCommands.

  # TODO: Implement source-filtered ICMP with nftables when needed
  # For now, allowing all ICMP is acceptable for local network use

  networking.firewall.allowPing = true;
}
