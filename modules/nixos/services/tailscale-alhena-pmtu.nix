{ pkgs, ... }:
{
  # Alhena's WSL Tailscale endpoint has an observed 1280-byte outer PMTU. Leave
  # 64 bytes for WireGuard encapsulation while keeping tailscale0 at 1280 for
  # IPv6's minimum MTU. Monitor route changes so Tailscale netmap updates cannot
  # silently replace this per-peer clamp.
  systemd.services.tailscale-alhena-pmtu = {
    description = "Clamp the IPv4 Tailscale route to Alhena's WSL endpoint";
    wantedBy = [ "tailscaled.service" ];
    partOf = [ "tailscaled.service" ];
    after = [ "tailscaled.service" ];
    path = [ pkgs.iproute2 ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "1s";
    };
    script = ''
      apply_route() {
        route="$(ip -4 -details route show table 52 exact 100.98.74.2/32)"
        case "$route" in
          *"dev tailscale0"*)
            case "$route" in
              *"mtu lock 1216"*) return 0 ;;
            esac
            ip -4 route change 100.98.74.2/32 dev tailscale0 table 52 mtu lock 1216
            ;;
        esac
      }

      # Subscribe before reconciling the existing route; this closes the gap
      # between an initial one-shot fix and listening for later replacements.
      coproc ROUTE_MONITOR { ip -4 monitor route; }
      monitor_fd="''${ROUTE_MONITOR[0]}"
      apply_route
      while IFS= read -r -u "$monitor_fd" event; do
        case "$event" in
          *"100.98.74.2"*) apply_route ;;
        esac
      done
      echo "Tailscale route monitor stopped" >&2
      exit 1
    '';
  };
}
