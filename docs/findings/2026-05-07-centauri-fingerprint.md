# Centauri Fingerprint Reader Notes

## Hardware
- Host: `centauri`
- Sensor: `06cb:009a` (`Synaptics Metallica MIS Touch Fingerprint Reader`)

## Current Driver Reality
- As of May 7, 2026, `06cb:009a` is still not listed in the upstream `libfprint` supported device list.
- Plain `services.fprintd.enable = true;` is not enough for this sensor.
- Repo now uses the external flake `ahbnr/nixos-06cb-009a-fingerprint-sensor` on branch `24.11`.

## Repo Wiring
- Flake input: `nixos-06cb-009a-fingerprint-sensor`
- Focused service module: `modules/nixos/services/fingerprint-06cb-009a.nix`
- Enabled on host: `nixos/machines/centauri/default.nix`

## Notes
- The external flake is currently used as package source, not as a direct imported NixOS module.
- Local module patches the upstream `python-validity` derivation so it still evaluates on this repo's `nixpkgs` / Python stack.
- PAM fingerprint auth is wired locally for `gdm-fingerprint`, `login`, `sudo`, `swaylock`, and `polkit-1`.
- `gdm-fingerprint` is declared manually because stock NixOS only auto-generates it when `services.fprintd.enable = true`, while this setup uses `open-fprintd` with `services.fprintd.enable = false`.
- If fingerprint auth stops working after future NixOS upgrades, verify that the external flake has a matching branch for the target release before changing local wiring.

## Maintenance Checklist
- After `nix flake update`, run `nix eval .#nixosConfigurations.centauri.config.system.build.toplevel`.
- After rebuild on `centauri`, test `fprintd-verify`, `sudo -v`, swaylock unlock, and a fresh GDM login.
- If eval fails in the fingerprint stack, inspect `modules/nixos/services/fingerprint-06cb-009a-python-validity.nix` first. That local wrapper is the most likely point to need refresh when Python packaging changes in `nixpkgs`.

## Upstream Checkpoints
- Check whether `06cb:009a` appears in the official libfprint supported device list:
  - <https://fprint.freedesktop.org/supported-devices.html>
- Check whether the external flake has a branch matching the repo's target NixOS release:
  - <https://github.com/ahbnr/nixos-06cb-009a-fingerprint-sensor>
- If `06cb:009a` lands in upstream libfprint, prefer removing the custom `open-fprintd` / `python-validity` path and switching back to standard `services.fprintd`.
