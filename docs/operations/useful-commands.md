# Operations Overview

This section explains the operational side of the repo at a design level. It is
less about memorizing commands and more about understanding the kinds of work
the repo supports and how those workflows fit together.

## Operational Model

The repo favors a layered workflow:

- evaluate early
- validate before larger changes
- apply only once the system shape is understood

That mirrors the architecture of the repo itself: composition first, then
verification, then activation.

## Main Areas

- validation and evaluation
  - checking flake outputs and machine shape before doing heavier work
- local rebuild and rollback
  - applying and recovering machine state
- user-session operations
  - the runtime side of the configured environment
- store maintenance
  - keeping the local Nix environment healthy
- VPS install flow
  - the remote-install and migration-specific operational path

## Why This Section Exists

Operational docs change more often than architecture docs, but they still
benefit from a stable overview. This section gives the map, while the scripts,
machine docs, and findings carry the more tactical details.

## Where To Look Next

- [README.md](../../README.md)
- [validate.sh](../../validate.sh)
- [nixos/machines/albaldah/README.md](../../nixos/machines/albaldah/README.md)
- [docs/vps/README.md](../vps/README.md)
