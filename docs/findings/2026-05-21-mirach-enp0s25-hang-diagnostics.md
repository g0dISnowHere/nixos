# Mirach `enp0s25` Hang Diagnostics (2026-05-21)

## Scope

Temporary diagnostics are enabled on `mirach` for Intel `e1000e` hang investigation:

- periodic snapshots every 10 seconds
- immediate snapshot trigger on kernel line `Detected Hardware Unit Hang`

Logs are written to:

- `/home/djoolz/Documents/01_config/mine/enp0s25-diag/`

## Enabled Diagnostics

Implementation lives in:

- `nixos/machines/mirach/ethernet-diagnostics.nix`

Services:

- `enp0s25-diag-poller.service`
- `enp0s25-hang-capture.service`
- `enp0s25-router-ping-watchdog.service`

Key captured data:

- `ethtool -i/-k/--show-eee/-S enp0s25`
- `ip -s link show enp0s25 br0`
- `bridge -s link`
- `nstat -az`
- `ss -s`
- recent network-relevant kernel lines
- CPU, interrupt, softnet, socket, qdisc, and focused NIC error counters

Triggered captures are cooldown-gated so a single hang storm does not create a
new file for every repeated kernel line. Periodic snapshots keep only a short
rolling window; incident context directories preserve the preceding window.

## Option 3 (Enabled 2026-05-31): A/B Offload Test

Purpose: check whether hangs correlate with offload features.

Baseline evidence:

```bash
journalctl -k --since today | rg "Detected Hardware Unit Hang" | wc -l
```

Current test:

```bash
sudo ethtool -K enp0s25 tso off gso off gro off
```

This is now applied by `nixos/machines/mirach/libvirtd.nix` in the
`enp0s25-link-tuning` service, alongside EEE disablement and WoL disablement.
Collect the same hang count after the change and compare frequency.

Revert:

```bash
sudo ethtool -K enp0s25 tso on gso on gro on
```

If this helps, keep the host-local systemd oneshot setting. If it does not,
the next likely fix is to avoid this NIC for the bridged workload.

## Option 4 (Documented, Not Enabled): Runtime Reset Hook

Purpose: temporary uptime mitigation while evidence is gathered.

Trigger condition:

- kernel line contains `enp0s25: Detected Hardware Unit Hang`

Action:

```bash
sudo ip link set enp0s25 down
sleep 2
sudo ip link set enp0s25 up
```

Notes:

- This is mitigation, not root-cause fix.
- It can interrupt active sessions and VM traffic briefly.
- If adopted, gate with cooldown logic to avoid reset loops.

## Cleanup

To disable temporary diagnostics after data collection:

1. remove `./ethernet-diagnostics.nix` from `nixos/machines/mirach/default.nix`
2. remove `nixos/machines/mirach/ethernet-diagnostics.nix`
3. `sudo nixos-rebuild switch --flake .#mirach`
4. optionally archive then remove `/var/log/enp0s25-diag/`
