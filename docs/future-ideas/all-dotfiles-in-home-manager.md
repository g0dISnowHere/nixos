# Selective Git-Synced Dotfiles

## Decision

Keep one repository: `~/nixos`. Do not create a second dotfiles repository.

Application-facing configuration lives as native files under `dotfiles/`. Home
Manager must not deploy or own those live application paths. Keep it for Nix
packages, session environment, and user services.

Do not manage all of `~/.config/`. Every tracked path needs an explicit reason.

## Deployment Modes

### Direct links

Use direct symlinks from a selected live path into `~/nixos/dotfiles/` when an
application only reads its config or preserves the link when saving:

```text
~/.config/niri/config.kdl
  -> ~/nixos/dotfiles/modules/compositor/niri/config.kdl
```

This makes intentional UI or editor changes immediately visible in `git diff`.
The link tool must be idempotent, touch only an explicit allowlist, back up
collisions, and have an unlink mode that removes only links it created.

### Explicit copy sync

Use explicit `--from-live` and `--to-live` copy operations for applications
that atomically replace configuration files. The operation must show a diff,
refuse to overwrite uncommitted repository changes, and back up the live
destination before applying repository content.

Never run automatic bidirectional synchronization: conflicting edits require
Git conflict resolution, not last-writer-wins copying.

## Initial Scope

Already tracked and suitable for direct links:

- Niri
- Waybar
- Mako
- Fuzzel
- Nautilus scripts and extensions

Potential copy-sync candidates, after a live-file inventory on the machine that
runs them:

- Herdr `config.toml`; exclude logs, sessions, release notes, and plugin state.
- GitHub CLI `config.yml`; exclude `hosts.yml`.
- Flatpak OrcaSlicer, PrusaSlicer, and FreeCAD preferences and user presets.
  Flatpak live data is under `~/.var/app/<app-id>/`; exclude caches, logs,
  backups, autosaves, bundled presets, and downloaded add-ons.
- Codex policy files (`AGENTS.md`, rules) and selected mutable settings;
  exclude authentication, logs, sessions, databases, queues, caches, plugins,
  and generated memories.

## Exclusions

- All of `~/.ssh`: Nix manages the intended SSH configuration; never track
  keys, known hosts, or host-specific state here.
- `htop` and `btop`: do not track unless deliberate portable preferences are
  added.
- Browser, Electron, editor, AI-agent, and Flatpak runtime directories by
  default.
- Credentials, tokens, keyrings, GnuPG files, shell history, databases,
  locks, caches, generated state, and logs.

## Status

Proposal only. No general link or copy-sync tool exists yet. Start with the
existing desktop files; add an application only when its configuration has been
intentionally changed and reproducing that choice on another machine is worth
the maintenance cost.