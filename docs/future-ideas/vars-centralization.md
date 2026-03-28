# Plan: Centralize Shared Vars

## Goal

Define shared variables once (user, system, desktop, role, hostname, etc.) and reuse them across NixOS and Home-Manager while keeping host-specific files for hardware and modules.

## Approach

Use a dedicated vars layout with clear separation of blocks, and a wrapper in `mkNixosSystem` to load/merge vars once and pass them to both NixOS and Home-Manager via `specialArgs` and `home-manager.extraSpecialArgs`.

## Vars layout (separate blocks)

- `vars/common.nix` — shared defaults (user, system, locale, timeZone, allowUnfree, stateVersion)
- `vars/user.nix` — user-specific values (username, homeDirectory, groups)
- `vars/roles/workstation.nix` — workstation defaults
- `vars/roles/homelab.nix` — homelab defaults
- `vars/hosts/centauri.nix` — per-host overrides
- `vars/hosts/mirach.nix` — per-host overrides

## Merge order

`common → user → role → host → explicit overrides`

## Steps

1. Add vars files listed above.
2. Import the vars module in `outputs.nix` so `self.vars`/`self.hosts` are available.
3. Add `mkNixosSystemFromHost` (wrapper) in `flake/lib.nix` to load and merge vars.
4. Update `flake/machines/workstations.nix` and `flake/machines/homelabs.nix` to use the wrapper and host vars.
5. Update `flake/homes/djoolz.nix` to consume `self.vars.user` and host/system/desktop values from vars.
6. Migrate any literal values (username, desktop, system, role, hostname) from machine files into vars.

## Files to touch

- `flake/vars.nix` (new aggregator if needed)
- `vars/common.nix`
- `vars/user.nix`
- `vars/roles/workstation.nix`
- `vars/roles/homelab.nix`
- `vars/hosts/centauri.nix`
- `vars/hosts/mirach.nix`
- `outputs.nix`
- `flake/lib.nix`
- `flake/machines/workstations.nix`
- `flake/machines/homelabs.nix`
- `flake/homes/djoolz.nix`

## Notes

- Keep host files for hardware and modules; vars only centralize shared values.
- Wrapper ensures consistent vars are visible to both NixOS and Home-Manager.
