# Albaldah

This directory contains the host-local slice of the `albaldah` VPS. It is small
by design: most behavior should come from reusable composition, while this
folder carries only the pieces that are truly specific to the host.

## Design Intent

The VPS follows the same broad repo philosophy as the other machines:

- shared behavior should stay shared
- host-specific overrides should stay local
- install-time concerns should be explicit rather than hidden in helpers

For `albaldah`, that means the directory mainly exists to express the VPS as a
specialized host without turning it into a one-off snowflake.

## Structure

- [default.nix](default.nix)
  - the host-specific configuration layer
- [hardware-configuration.nix](hardware-configuration.nix)
  - the hardware-detected baseline
- [disko.nix](disko.nix)
  - the disk-layout layer used by the install path

## Place In The Repo

`albaldah` is wired into the flake from `flake/machines/homelabs.nix` as a
headless VPS machine. This directory is therefore one layer in a larger
composition, not a standalone configuration world of its own.

## Related Docs

- [docs/findings/2026-03-28-vps-albaldah.md](../../../docs/findings/2026-03-28-vps-albaldah.md)
- [docs/vps/README.md](../../../docs/vps/README.md)
