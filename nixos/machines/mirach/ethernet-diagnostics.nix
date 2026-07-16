{ pkgs, ... }:
let
  physicalInterface = "enp0s25";
  bridgeInterface = "br0";
  routerIp = "192.168.3.1";
  pingFailureSeconds = 60;
  logDir = "/home/djoolz/Documents/01_config/mine/enp0s25-diag";
  periodicRetentionMinutes = 20;
  incidentContextCooldownMinutes = 20;
  triggerCaptureCooldownSeconds = incidentContextCooldownMinutes * 60;
  enablePerfSampling = false;

  snapshotScript = pkgs.writeShellScript "enp0s25-diag-snapshot" ''
    set -euo pipefail
    umask 022

    mkdir -p ${logDir}

    ts="$(date -Iseconds)"
    safe_ts="$(date +%Y%m%dT%H%M%S%z)"
    event="$1"
    case "$event" in
      hang-trigger) prefix="hang-trigger" ;;
      *) prefix="snapshot" ;;
    esac

    # Keep a rolling window of periodic snapshots only; preserve hang-trigger captures.
    find ${logDir} -maxdepth 1 -type f -name 'snapshot-*.log' -mmin +${toString periodicRetentionMinutes} -delete || true

    # On hang-trigger, preserve the preceding periodic window once per incident window.
    if [ "$event" = "hang-trigger" ]; then
      if ! find ${logDir} -maxdepth 1 -type d -name 'hang-context-*' -mmin -${toString incidentContextCooldownMinutes} -print -quit | rg -q .; then
        context_dir="${logDir}/hang-context-''${safe_ts}"
        mkdir -p "$context_dir"
        find ${logDir} -maxdepth 1 -type f -name 'snapshot-*.log' -mmin -${toString periodicRetentionMinutes} \
          -exec cp -n -t "$context_dir" {} + || true
      fi
    fi

    out="${logDir}/''${prefix}-''${safe_ts}.log"

    {
      echo "timestamp=''${ts}"
      echo "host=$(hostname)"
      echo "event=''${event}"
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

      echo "== ethtool -S focused counters (${physicalInterface}) =="
      ethtool -S ${physicalInterface} 2>/dev/null | rg -i "rx_missed_errors|rx_no_buffer|tx_timeout|hang|reset|timeout|carrier|drop" || true
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

      echo "== monotonic time (proc uptime) =="
      cat /proc/uptime || true
      echo

      echo "== ss -s =="
      ss -s || true
      echo

      echo "== sockstat =="
      cat /proc/net/sockstat || true
      cat /proc/net/sockstat6 || true
      echo

      echo "== CPU/load snapshot =="
      uptime || true
      cat /proc/loadavg || true
      echo

      echo "== interrupts =="
      cat /proc/interrupts || true
      echo

      echo "== irq affinity list =="
      grep . /proc/irq/*/smp_affinity_list 2>/dev/null || true
      echo

      echo "== softnet stat =="
      cat /proc/net/softnet_stat || true
      echo

      echo "== qdisc stats (${physicalInterface}, ${bridgeInterface}) =="
      tc -s qdisc show dev ${physicalInterface} || true
      tc -s qdisc show dev ${bridgeInterface} || true
      echo

      echo "== top cpu processes (ps) =="
      ps -eo pid,ppid,comm,%cpu,%mem,state --sort=-%cpu | head -n 11 || true
      echo

      echo "== top threads (ps -eLo) =="
      ps -eLo pid,tid,psr,pcpu,comm --sort=-pcpu | head -n 30 || true
      echo

      echo "== top cpu processes (top, batch) =="
      top -b -n 1 | head -n 20 || true
      echo

      if [ "${if enablePerfSampling then "1" else "0"}" = "1" ]; then
        echo "== perf sample (testing only; bounded 5s) =="
        perf_data="$(mktemp "${logDir}/perf-''${safe_ts}-XXXXXX.data")"
        perf record -a -g -o "$perf_data" -- sleep 5 >/dev/null 2>&1 || true
        perf report --stdio -i "$perf_data" --no-children --sort comm,dso,symbol 2>/dev/null | head -n 120 || true
        rm -f "$perf_data"
        echo
      fi

      echo "== kernel log delta (last 120 lines, network-relevant) =="
      journalctl -k -n 120 --no-pager | rg -i "${physicalInterface}|${bridgeInterface}|e1000e|NETDEV|hang|link|carrier" || true
    } >> "$out"
  '';
in
{
  environment.systemPackages = with pkgs; [ ethtool ];

  systemd = {
    tmpfiles.rules = [ "d ${logDir} 0755 root root - -" ];

    # Periodic snapshots for drift-over-time analysis.
    services = {
      enp0s25-diag-snapshot = {
        description = "Capture periodic Ethernet diagnostics for ${physicalInterface}";
        serviceConfig = {
          Type = "oneshot";
        };
        path = with pkgs; [
          coreutils
          ethtool
          gnugrep
          inetutils
          iproute2
          perf
          procps
          ripgrep
          systemd
        ];
        script = ''
          ${snapshotScript} periodic
        '';
      };

      # Poll every 10 seconds to keep near-real-time snapshots during incidents.
      enp0s25-diag-poller = {
        description = "Continuously collect Ethernet diagnostics for ${physicalInterface}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "2s";
        };
        path = with pkgs; [
          coreutils
          ethtool
          gnugrep
          inetutils
          iproute2
          perf
          procps
          ripgrep
          systemd
        ];
        script = ''
          while true; do
            ${snapshotScript} periodic
            sleep 10
          done
        '';
      };

      # Triggered capture: when the kernel emits a hardware hang, grab state immediately.
      enp0s25-hang-capture = {
        description = "Capture immediate diagnostics when e1000e hardware hangs are logged";
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "2s";
        };
        path = with pkgs; [
          coreutils
          ethtool
          gnugrep
          inetutils
          iproute2
          perf
          procps
          ripgrep
          systemd
        ];
        script = ''
          last_capture=0
          journalctl -kf -n0 --no-pager | while IFS= read -r line; do
            if printf '%s\n' "$line" | rg -q "${physicalInterface}: (Detected Hardware Unit Hang|NIC Link is Down)"; then
              now="$(date +%s)"
              if [ "$((now - last_capture))" -ge ${toString triggerCaptureCooldownSeconds} ]; then
                ${snapshotScript} hang-trigger
                last_capture="$now"
              fi
            fi
          done
        '';
      };

      # Triggered capture: if the local router is unreachable for 60s, snapshot immediately.
      enp0s25-router-ping-watchdog = {
        description = "Capture diagnostics when router ping fails for ${toString pingFailureSeconds}s";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "2s";
        };
        path = with pkgs; [
          coreutils
          ethtool
          gnugrep
          inetutils
          iproute2
          perf
          procps
          ripgrep
          systemd
        ];
        script = ''
          failures=0
          while true; do
            if ping -n -c 1 -W 1 ${routerIp} >/dev/null 2>&1; then
              failures=0
            else
              failures=$((failures + 1))
            fi

            if [ "$failures" -ge ${toString pingFailureSeconds} ]; then
              printf '%s\n' "router ping failed for ${toString pingFailureSeconds}s: ${routerIp}" \
                | systemd-cat -t enp0s25-router-ping-watchdog -p warning
              ${snapshotScript} hang-trigger
              failures=0
              sleep 30
            fi

            sleep 1
          done
        '';
      };
    };
  };
}
