# Mirach `enp0s25` Hang Diagnostics (2026-05-21)

## Scope

Temporary diagnostics are enabled on `mirach` for Intel `e1000e` hang investigation:

- periodic snapshots every 10 seconds
- immediate snapshot trigger on kernel line `Detected Hardware Unit Hang`

Logs are written to:

- `/var/log/enp0s25-diag/`

## Enabled Diagnostics

Implementation lives in:

- `nixos/machines/mirach/ethernet-diagnostics.nix`

Services:

- `enp0s25-diag-poller.service`
- `enp0s25-hang-capture.service`

Key captured data:

- `ethtool -i/-k/--show-eee/-S enp0s25`
- `ip -s link show enp0s25 br0`
- `bridge -s link`
- `nstat -az`
- `ss -s`
- recent network-relevant kernel lines

## Option 3 (Documented, Not Enabled): A/B Offload Test

Purpose: check whether hangs correlate with offload features.

Baseline day (no changes):

```bash
journalctl -k --since today | rg "Detected Hardware Unit Hang" | wc -l
```

Test day (temporary):

```bash
sudo ethtool -K enp0s25 tso off gso off gro off
```

Collect same hang count and compare frequency.

Revert:

```bash
sudo ethtool -K enp0s25 tso on gso on gro on
```

If this helps, consider adding a host-local systemd oneshot or NixOS module setting so behavior is explicit and reproducible.

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
