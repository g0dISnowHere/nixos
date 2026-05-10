# Reasons For `stateVersion`

Repo pins both `system.stateVersion` and `home.stateVersion` to `25.11`.

Do not change casually.

Why:

- compatibility markers, not upgrade toggles
- they affect module defaults during eval, which can change generated system or home profile
- they may preserve older data-format or filesystem-layout defaults for stateful modules and programs
- upgrading `nixpkgs`, `home-manager`, or flake lock is separate from changing `*.stateVersion`

Short version:

- `system.stateVersion` preserves compatibility for stateful NixOS services and on-disk data
- `home.stateVersion` preserves compatibility for Home Manager defaults and user-state layout
- rolling back generation does not necessarily undo app-level migrations already written on disk

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

- local config has no custom modules branching directly on either state version
- practical gating risk comes from upstream NixOS and Home Manager modules, not repo-local conditionals
