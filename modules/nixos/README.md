# NixOS Modules

`modules/nixos/` holds reusable system-level modules. These modules describe
shared machine behavior that can be composed into multiple hosts.

## Main Areas

- `desktop/`
  - desktop environment and desktop infrastructure modules
- `roles/`
  - higher-level shared machine profiles
- `services/`
  - reusable service modules
- `system/`
  - core system behavior and platform-level settings
- `virtualisation/`
  - container and virtualization building blocks

## Design Intent

This directory is where shared system policy belongs. Machine-specific behavior
should stay out unless the module is explicitly tied to a single host. Keep
repo-wide design rationale in `docs/`; this README should stay scoped to
`modules/nixos/`.
