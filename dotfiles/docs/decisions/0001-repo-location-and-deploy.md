# Decision 0001 — Repo location and deployment method

Date: 2026-02-14

## Decision
- Repo location is `/home/djoolz/Documents/01_config/mine/dotfiles`.
- Deployment method is symlink-based via Home Manager-managed links to the
  repo-backed files in `dotfiles/`.
- `dotfiles/scripts/link.sh` remains available as a manual helper for
  troubleshooting or ad-hoc relinking outside Home Manager.
- Workspace map is frozen in `dotfiles/state/workspace-map.md`.

## Notes
If the repo location changes, update any paths that assume this location
(notably the `repoRoot` / `dotfilesRoot` wiring used by the Home Manager
desktop modules).
