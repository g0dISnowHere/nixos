# Capability Module Follow-Ups

The broad role-module migration is implemented. Remaining ideas belong here
until they are either implemented or promoted into canonical architecture docs.

## Possible Follow-Ups

- Split `modules/nixos/services/ssh-server.nix` if SSH, Mosh, and VS Code
  Remote should not always travel together.
- Add more conflict assertions where capabilities are mutually exclusive.
  Docker rootful versus rootless already has this guardrail.
- Add small machine-intent bundles only if repeated import groups become noisy.
  Keep them transparent and avoid recreating broad roles.
- Expand `flake.nixosModules` exports if external flakes start consuming this
  repo's capability modules.
- Consider a lightweight reference checklist for adding a new machine with
  explicit capabilities.

## Current Canonical Doc

The implemented design is documented in
[`docs/architecture/capability-modules.md`](../architecture/capability-modules.md).
