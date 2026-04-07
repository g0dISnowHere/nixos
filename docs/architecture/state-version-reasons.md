# Reasons For `stateVersion`

This repo does not treat `system.stateVersion` or `home.stateVersion` as
repo-wide constants.

Do not change these values casually.

Why:

- They are compatibility markers, not upgrade toggles.
- They influence module defaults during evaluation, which can change the generated system or home profile.
- They may keep older data-format or filesystem-layout defaults for stateful modules and programs.
- Upgrading `nixpkgs`, `home-manager`, or the flake lock is separate from changing `*.stateVersion`.

Short version:

- `system.stateVersion` exists to preserve compatibility with stateful NixOS services and on-disk data.
- `home.stateVersion` exists to preserve compatibility with Home Manager defaults and user-state layout.
- Rolling back a generation does not necessarily undo application-level migrations that already happened on disk.

References:

- NixOS option reference for `system.stateVersion`:
  https://mynixos.com/nixpkgs/option/system.stateVersion
- NixOS manual, which documents stateful service behavior such as PostgreSQL version defaults being tied to `system.stateVersion`:
  https://nixos.org/nixos/manual/index.html
- NixOS Wiki FAQ guidance not to bump `system.stateVersion` casually:
  https://wiki.nixos.org/wiki/FAQ
- Home Manager manual and option reference for `home.stateVersion`:
  https://home-manager.dev/manual/
  https://home-manager.dev/manual/23.05/options.html#opt-home.stateVersion

Repo-specific note:

- State versions are machine-specific compatibility markers and should stay
  pinned where each machine or standalone home configuration declares them.
- New machines may legitimately keep older state-version values when they are
  migrated into this repo from an earlier standalone configuration.
- We checked the local config and found no custom modules in this repo that
  branch on either state version directly.
- That means the practical gating risk here comes from upstream NixOS and Home
  Manager modules, not from repo-local conditional logic.
