# Log Search

Quick `journalctl` patterns for precise incident timing without dumping huge
outputs.

## Find Exact Event Window (First/Last/Count)

```bash
journalctl -k --since '2026-05-21 15:00:00' --until '2026-05-21 15:20:00' --no-pager \
  | rg 'Detected Hardware Unit Hang' \
  | awk 'NR==1{first=$1" "$2" "$3} {last=$1" "$2" "$3; c++} END{print "count=" c; print "first=" first; print "last=" last}'
```

## Discover Exact Message Before Broad Search

```bash
journalctl -k --since '2026-05-21 15:07:30' --until '2026-05-21 15:08:30' --no-pager | tail -n 80
```

Use the exact repeated phrase from the sample as the `rg` term.

## Show Only Start/End Matching Lines

```bash
journalctl -k --since '2026-05-21 15:00:00' --until '2026-05-21 15:20:00' --no-pager \
  | rg 'Detected Hardware Unit Hang' \
  | sed -n '1p;$p'
```

## Unit-Scoped Logs in Time Window

```bash
journalctl -u enp0s25-diag-poller.service --since '2026-05-21 15:00:00' --until '2026-05-21 15:20:00' --no-pager
```

## Keep Searches Tight

- start with `-k` (kernel) or `-u <unit>` (single unit)
- use exact `--since`/`--until`
- filter with one precise `rg` phrase first, then widen only if needed
