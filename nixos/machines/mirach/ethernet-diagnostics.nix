{ pkgs, ... }:
let
  physicalInterface = "enp0s25";
  bridgeInterface = "br0";
  logDir = "/var/log/enp0s25-diag";

  snapshotScript = pkgs.writeShellScript "enp0s25-diag-snapshot" ''
    set -euo pipefail

    mkdir -p ${logDir}

    ts="$(date -Iseconds)"
    safe_ts="$(date +%Y%m%dT%H%M%S%z)"
    out="${logDir}/snapshot-''${safe_ts}.log"

    {
      echo "timestamp=''${ts}"
      echo "host=$(hostname)"
      echo "event=$1"
      echo

      echo "== ethtool -i ${physicalInterface} =="
      ethtool -i ${physicalInterface} || true
      echo

      echo "== ethtool ${physicalInterface} =="
      ethtool ${physicalInterface} || true
      echo

      echo "== ethtool --show-eee ${physicalInterface} =="
      ethtool --show-eee ${physicalInterface} || true
      echo

      echo "== ethtool -k ${physicalInterface} =="
      ethtool -k ${physicalInterface} || true
      echo

      echo "== ethtool -S ${physicalInterface} =="
      ethtool -S ${physicalInterface} || true
      echo

      echo "== ip -s link show ${physicalInterface} =="
      ip -s link show ${physicalInterface} || true
      echo

      echo "== ip -s link show ${bridgeInterface} =="
      ip -s link show ${bridgeInterface} || true
      echo

      echo "== bridge -s link =="
      bridge -s link || true
      echo

      echo "== nstat -az =="
      nstat -az || true
      echo

      echo "== ss -s =="
      ss -s || true
      echo

      echo "== kernel log delta (last 120 lines, network-relevant) =="
      journalctl -k -n 120 --no-pager | rg -i "${physicalInterface}|${bridgeInterface}|e1000e|NETDEV|hang|link|carrier" || true
    } >> "$out"
  '';
in {
  environment.systemPackages = with pkgs; [ ethtool ];

  systemd = {
    tmpfiles.rules = [ "d ${logDir} 0750 root root - -" ];

    # Periodic snapshots for drift-over-time analysis.
    services = {
      enp0s25-diag-snapshot = {
        description =
          "Capture periodic Ethernet diagnostics for ${physicalInterface}";
        serviceConfig = { Type = "oneshot"; };
        path = with pkgs; [ coreutils ethtool gnugrep iproute2 systemd ];
        script = ''
          ${snapshotScript} periodic
        '';
      };

      # Poll every 10 seconds to keep near-real-time snapshots during incidents.
      enp0s25-diag-poller = {
        description =
          "Continuously collect Ethernet diagnostics for ${physicalInterface}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "2s";
        };
        path = with pkgs; [ coreutils ethtool gnugrep iproute2 systemd ];
        script = ''
          while true; do
            ${snapshotScript} periodic
            sleep 10
          done
        '';
      };

      # Triggered capture: when the kernel emits a hardware hang, grab state immediately.
      enp0s25-hang-capture = {
        description =
          "Capture immediate diagnostics when e1000e hardware hangs are logged";
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "2s";
        };
        path = with pkgs; [ coreutils ethtool gnugrep iproute2 systemd ];
        script = ''
          journalctl -kf -n0 --no-pager | while IFS= read -r line; do
            if printf '%s\n' "$line" | rg -q "${physicalInterface}: Detected Hardware Unit Hang"; then
              ${snapshotScript} hang-trigger
            fi
          done
        '';
      };
    };
  };
}
