# Fingerprint Maintenance

Quick checklist for the `centauri` fingerprint sensor (`06cb:009a`).

## Current Repo Wiring
- Local wrapper package:
  - `modules/nixos/services/fingerprint-06cb-009a-python-validity.nix`
- Local service wiring:
  - `modules/nixos/services/fingerprint-06cb-009a.nix`
- External flake input:
  - `nixos-06cb-009a-fingerprint-sensor`

## When To Check This
- after `nix flake update`
- after moving the repo to a new NixOS release
- when `nix eval .#nixosConfigurations.centauri.config.system.build.toplevel` fails
- when fingerprint login or `sudo` stops working

## Check Upstream Support

If `06cb:009a` appears here, re-evaluate whether the custom stack is still needed:

```bash
curl -fsSL https://fprint.freedesktop.org/supported-devices.html | rg '06cb:009a'
```

Official list:
- <https://fprint.freedesktop.org/supported-devices.html>

## Check External Flake Branch

See whether the external flake has a branch matching the repo's target NixOS release:

```bash
rg -n 'nixos-06cb-009a-fingerprint-sensor|url = ' flake.nix flake.lock
```

Project:
- <https://github.com/ahbnr/nixos-06cb-009a-fingerprint-sensor>

## Update `python-validity`

The local wrapper currently pins:
- `version`
- GitHub `rev`
- `sha256`

File:
- `modules/nixos/services/fingerprint-06cb-009a-python-validity.nix`

Typical update flow:

1. Change `version`.
2. Keep `rev = version;` if upstream tag naming still matches.
3. Temporarily set:

```nix
sha256 = lib.fakeSha256;
```

4. Run:

```bash
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
```

5. Replace `sha256` with the hash Nix prints.
6. Re-run eval.

## Validate After Any Change

```bash
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#centauri
sudo systemctl status python3-validity
fprintd-verify
sudo -v
```

Also test:
- swaylock unlock
- fresh GDM login
- a polkit prompt

## Likely Failure Point

If eval breaks after a `nixpkgs` update, the most likely local fix point is:

- `modules/nixos/services/fingerprint-06cb-009a-python-validity.nix`

Reason:
- this wrapper carries compatibility glue for current Python packaging in `nixpkgs`
- upstream `python-validity` packaging may lag behind
