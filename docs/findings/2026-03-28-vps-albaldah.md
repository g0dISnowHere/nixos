# Albaldah Directory Outline

This is a light overview of the `albaldah` host layout in this repo.

## What It Is

`albaldah` is the headless STRATO VPS machine definition. The flake wires it in
from [flake/machines/homelabs.nix](../../flake/machines/homelabs.nix) as a `homelab` host with host-specific overrides and a `disko` install path.

## Directory Structure

- [default.nix](../../nixos/machines/albaldah/default.nix)
  - host-specific behavior such as networking, bootloader, SSH access, timezone,
    and the attached Home Manager user
- [hardware-configuration.nix](../../nixos/machines/albaldah/hardware-configuration.nix)
  - hardware detection only
  - does not own `/` or `/boot`
- [disko.nix](../../nixos/machines/albaldah/disko.nix)
  - disk layout for remote install and rebuilds
- [README.md](../../nixos/machines/albaldah/README.md)
  - host-local install notes and preflight checks

## Related Docs

- [README.md](../../README.md)
  - repo-level overview
- [docs/README.md](../README.md)
  - docs index
- [docs/operations/useful-commands.md](../operations/useful-commands.md)
  - install and test commands for `albaldah`
- [docs/vps/nixos-migration-audit-2026-03-28.md](../vps/nixos-migration-audit-2026-03-28.md)
  - VPS audit and migration context
- [docs/vps/backup-reimport-runbook-2026-03-28.md](../vps/backup-reimport-runbook-2026-03-28.md)
  - restore workflow for preserved services

## Current Shape

- single-disk `disko` layout on `/dev/vda`
- declarative `8 GiB` swapfile on the root filesystem
- BIOS/GRUB boot path
- `systemd-networkd` on `ens6` with DHCP and IPv6
- SSH-first remote administration

For implementation details, read the machine files directly. This note is only
meant to explain the structure and where to look next.
