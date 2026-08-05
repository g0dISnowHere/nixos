# Storage Hogs Audit - 2026-07-25

Question: after adding limits to audit log gathering, are there similar storage-growth risks in this repo?

Scope checked: `scripts/`, `modules/`, `nixos/machines/`, `dotfiles/`, and relevant docs. Evidence came from targeted code search/read, TokenSave context, and read-only scout agents. No files were changed during the audit.

## Likely storage hogs

### `nixos/machines/mirach/ethernet-diagnostics.nix`

Risk: high.

Evidence:

- `logDir = "/home/djoolz/Documents/01_config/mine/enp0s25-diag"`.
- Periodic `snapshot-*.log` files are bounded by a 20-minute cleanup window.
- `hang-trigger-*` logs and `hang-context-*` directories are explicitly preserved.
- Trigger services can create incident captures from kernel hang events and router-ping failures.

Why it can grow: repeated network incidents can accumulate preserved incident logs and context directories indefinitely. The output path is inside the checkout, but `enp0s25-diag/` is ignored by `.gitignore`.

Existing limit: periodic snapshots only. No hard cap for `hang-trigger-*` or `hang-context-*`.

Suggested fix: add age/count/size retention for incident artifacts, or move incident captures outside the repo checkout and manage them with tmpfiles/logrotate-style policy.

### `modules/nixos/services/crowdsec.nix` / `/var/log/traefik/access.log`

Risk: medium-high.

Evidence:

- CrowdSec is configured to consume `/var/log/traefik/access.log`.
- The module creates `/var/log/traefik` with tmpfiles.
- No repo-local logrotate or retention policy was found for the access log.
- The CrowdSec module is active on `albaldah`.

Why it can grow: if the Traefik-side producer does not rotate `/var/log/traefik/access.log`, the file can grow without bound while CrowdSec tails it.

Existing limit: none observed in this repo.

Suggested fix: define a host-side rotation policy for `/var/log/traefik/access.log`, or ensure the Traefik container owns rotation with explicit max size/file count.

### `dotfiles/modules/ui/noctalia/settings.json` clipboard history

Risk: medium-high.

Evidence:

- `clipboardWatchImageCommand` runs `wl-paste --type image --watch cliphist store`.
- `clipboardWatchTextCommand` runs `wl-paste --type text --watch cliphist store`.
- `enableClipboardHistory` is true.
- `dotfiles/modules/compositor/niri/config.kdl` binds `Mod+V` to the Noctalia clipper.

Why it can grow: copied text and images are continuously persisted by `cliphist store`. No repo-local cliphist retention, max-items, or cleanup policy was found.

Existing limit: none observed in this repo.

Note: storage path and default retention are tool-defined, not configured here. The unbounded-growth claim is therefore partly inferred from the absence of repo-local limits.

Suggested fix: add a cliphist cleanup policy or configure Noctalia/cliphist to bound stored entries, especially image entries.

### `dotfiles/modules/ui/noctalia/settings.json` notification history

Risk: medium.

Evidence:

- `NotificationHistory` is enabled in the module list.
- `saveToHistory` is true for `critical`, `low`, and `normal` notifications.
- `respectExpireTimeout` is false.
- No max-items, max-age, or cleanup setting was found for Noctalia notification history.

Why it can grow: all notification urgencies are retained, and repo config does not bound the history.

Existing limit: none observed in this repo.

Note: storage path/backend is not configured here, so this is a plausible risk rather than confirmed disk growth.

Suggested fix: find Noctalia's notification-history storage and add either a configured cap or a cleanup job.

### `scripts/repair-mirach-gdm-users.sh`

Risk: medium.

Evidence:

- `--apply` creates `/root/mirach-gdm-account-repair-$(date ...)`.
- It copies account state files such as `/etc/passwd`, `/etc/group`, `/etc/shadow`, `/var/lib/nixos/uid-map`, and `/var/lib/nixos/gid-map` into that directory.
- No deletion or retention logic exists for those backup dirs.

Why it can grow: every apply run creates a unique backup tree under `/root`.

Existing limit: none.

Suggested fix: keep the newest N repair backups or delete backups older than a conservative age after a successful repair.

## Medium-confidence watch list

### `modules/nixos/services/flatpak.nix`

Risk: medium.

Evidence:

- Flatpak is enabled.
- Updates run on activation and weekly.
- No automatic `flatpak uninstall --unused` or equivalent cleanup policy was found.
- Active on `centauri` and `mirach`.

Why it can grow: unused runtimes and app data can accumulate over time.

Existing limit: none observed in repo config.

Note: this depends on Flatpak behavior and installed app churn.

Suggested fix: add a periodic unused-runtime cleanup if that matches operator preference.

### `modules/nixos/services/zigbee2mqtt.nix`

Risk: medium.

Evidence:

- The service runs `zigbee2mqtt --data /home/djoolz/.z2m`.
- The directory is created on start.
- No cleanup/rotation/retention settings were found.
- Active on `mirach`.

Why it can grow: Zigbee2MQTT data directories commonly contain persistent DB/state, coordinator backups, and logs.

Existing limit: none observed in repo config.

Note: exact growth depends on Zigbee2MQTT runtime behavior and local config not shown here.

Suggested fix: inspect `/home/djoolz/.z2m` on the host and add retention if logs/backups are accumulating.

### `scripts/sync-pnpm-globals.sh` and `scripts/sync-uv-tools.sh`

Status: fixed after this audit.

Evidence before fix:

- `scripts/sync-pnpm-globals.sh` installed a runtime under `~/.local/share/mine/pnpm-globals`.
- `scripts/sync-uv-tools.sh` installed a runtime under `~/.local/share/mine/uv-tools`.
- Both had `remove_obsolete_wrappers()` as a no-op.
- `scripts/update-system.sh` can run these after successful rebuilds.
- No pnpm or uv cache pruning was present in repo config.

Why it could grow: package-manager caches/stores outside the fixed runtime dirs could accumulate across repeated syncs.

Fix applied:

- `scripts/sync-pnpm-globals.sh` now runs `pnpm store prune` after a successful sync.
- `scripts/sync-uv-tools.sh` now runs `uv cache prune` after a successful sync.

### `modules/nixos/services/homeassistant.nix`

Risk: latent medium.

Evidence:

- The module sets `services.home-assistant.configDir = "/home/djoolz/Documents/15_homeassistant"`.
- No recorder purge, DB size policy, backup pruning, media cleanup, or log retention was found nearby.
- No active host import was found during this audit.

Why it can grow: Home Assistant config dirs commonly accumulate history DBs, backups, media, and logs.

Existing limit: none observed in repo config.

Note: latent only unless the module is imported later.

Suggested fix: if this module becomes active, add a recorder purge/retention policy and backup cleanup.

## Already bounded / healthy examples

### Audit logs

- `modules/nixos/services/monitoring-baseline.nix` configures auditd with `max_log_file = 256`, `num_logs = 8`, and rotation actions.
- `scripts/audit-log-maintenance.py` supports count and size caps via `--keep-files` and `--keep-size-mib` and plans deletion of old rotated `audit.log*` files.

### Journald

- `modules/nixos/services/monitoring-baseline.nix` sets `SystemMaxUse=1G` and `MaxRetentionSec=7day`.

### Docker rootful logs and pruning

- `modules/nixos/virtualisation/docker.nix` sets Docker `log-driver = "journald"`.
- Docker `autoPrune` is enabled weekly.

### Home Manager conflict backups

- `modules/nixos/system/home-manager.nix` moves conflicting files into `~/.local/state/home-manager-backups` and deletes backup files older than 30 days.

### Login keyring backups

- `modules/home/services/keyring-backup.nix` keeps point-in-time login keyring backups but deletes everything beyond the newest 10 backups.

### Zsh history

- `modules/nixos/system/shell.nix` caps shell history at 50,000 entries with `histSize` and `SAVEHIST`.

### GNOME/legacy clipboard settings

- `modules/home/dconf/dconf.nix` caps `clipboard-indicator` with `cache-size = 100` and `history-size = 1000`.
- GNOME recent/temp cleanup settings are bounded in dconf.

## Large ignored files currently present in the checkout

A local size scan found ignored/generated storage in the checkout:

- `.tokensave/tokensave.db` and `.tokensave/tokensave.db-wal`.
- `dotfiles/modules/ui/noctalia/plugins/` media previews.
- `enp0s25-diag/` is ignored and is the output path for the Mirach Ethernet diagnostics.

These are not tracked repo files, but they are local disk consumers worth watching.
