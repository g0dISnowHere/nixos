# Albaldah

This directory contains host-local slice of `albaldah` VPS. It is small by
design: most behavior should come from reusable composition, while this folder
carries only pieces that are truly specific to host.

## Design Intent

VPS follows same broad repo philosophy as other machines:

- shared behavior should stay shared
- host-specific overrides should stay local
- install-time concerns should be explicit rather than hidden in helpers

For `albaldah`, that means directory mainly exists to express VPS as specialized
host without turning it into one-off snowflake.

## Structure

- [default.nix](default.nix)
  - host-specific configuration layer
- [hardware-configuration.nix](hardware-configuration.nix)
  - hardware-detected baseline
- [disko.nix](disko.nix)
  - disk-layout layer used by install path

## Place In Repo

`albaldah` is registered in `flake/machines/default.nix` and composed from
explicit capability modules such as CrowdSec, Tailscale routing, and Docker.
Remote administration is intended to go through Tailscale SSH plus provider
console, not public OpenSSH. VS Code Remote-SSH can ride that Tailscale path
because host also enables remote-session compatibility bit from
`modules/nixos/services/vscode-remote.nix`. This directory is therefore one
layer in larger composition, not standalone configuration world of its own.

Public SSH behavior in repo-managed config:

- `tcp/22` is not opened in NixOS firewall for `albaldah`
- remote admin is intended through Tailscale SSH, not public SSH port
- from public network path, SSH connection attempts should be dropped at
  firewall rather than actively refused by listening `sshd`

## Related Docs

- [docs/findings/2026-03-28-vps-albaldah.md](../../../docs/findings/2026-03-28-vps-albaldah.md)
- [docs/vps/README.md](../../../docs/vps/README.md)
