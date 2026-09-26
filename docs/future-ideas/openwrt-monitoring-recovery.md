# OpenWrt Monitoring Outage Recovery Plan

## Goal

Keep router metrics and logs observable through a home-WAN outage without fabricating historical data.

## Current state

Configured on `feat/syslog-receiver`; deployment is pending:

- Mirach accepts UDP syslog only from `192.168.3.1` and rotates the received files daily for seven days.
- Mirach Alloy tails `/var/log/remote/*/*.log` as `host="auriga",source="openwrt_syslog"` and forwards it to Loki.
- Mirach Alloy scrapes `192.168.3.1:9100` locally as `job="openwrt",host="auriga"` and remote-writes through its existing metric WAL.
- The backend's direct OpenWrt scrape is removed, preventing two collectors from writing the same time series.
- Loki delivery has an Alloy WAL and unlimited retry. The WAL retains segments for 168 hours under the persistent Alloy state directory. This uses Alloy's experimental Loki WAL feature.
- Alloy self-metrics are remote-written. Mirach exports one-minute WAN and DNS reachability metrics. Backend alerts cover router scrape failure, metric delivery lag, Loki delivery failures, WAN loss, and DNS loss.
- `nixos_firewall_allowed_port_info` now deduplicates overlapping firewall-port ranges before its textfile is written.

## Deployment and validation

1. Deploy Mirach before reloading the backend monitoring stack; otherwise the backend stops the direct scrape before the relay starts.
2. Send one OpenWrt syslog record and query Loki for `host="auriga",source="openwrt_syslog"`.
3. Verify `up{job="openwrt",host="auriga"}` arrives through the relay and alert rules remain inactive.
4. Do not disconnect the WAN for validation. After deployment, observe the relay, Loki stream, WAN/DNS probes, and transport alerts under normal traffic.

Backfill is intentionally out of scope. The system preserves future raw data instead.

## Verification

Before deployment:

- `nix eval .#nixosConfigurations.mirach.config.system.build.toplevel`

After deployment:

- send one router syslog event and query it in Loki;
- verify the relay's `up{job="openwrt",host="auriga"}` locally;
- inspect Loki delivery metrics/logs for zero dropped batches;
- observe the WAN/DNS probe metrics and transport alerts during normal operation.
