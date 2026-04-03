# Home Manager Modules

`modules/home/` holds reusable user-environment modules. These modules describe
shared user behavior that can be composed into multiple Home Manager profiles.

## Main Areas

- `packages/`
  - package groups by concern
- `programs/`
  - program-level configuration and user tooling
- `services/`
  - user services
- `desktop/`
  - desktop-specific user integration
- `dconf/` and `plasma/`
  - desktop-environment-specific configuration areas

## Design Intent

This layer should stay portable where possible. Shared modules should describe
user-environment behavior without hardcoding unnecessary machine-local
assumptions.

When a feature also exists at the NixOS layer, keep the Home Manager side
explicitly user-level. Prefer names like `gui` or `workstation-home` for
profile composition, and reserve desktop-environment naming for the NixOS
system layer.
