# Decision 0001 — Repo location and deployment method

Date: 2026-02-14

## Decision
- Repo location is `/home/djoolz/Documents/01_config/mine/dotfiles`.
- Deployment method is symlink-based via `dotfiles/scripts/link.sh`.
- Home Manager runs the symlink step on activation when `desktop == "niri"`.
- Workspace map is frozen in `dotfiles/state/workspace-map.md`.

## Notes
If the repo location changes, update any paths that assume this location (notably the Home Manager activation in `modules/home/desktop/niri.nix`).
