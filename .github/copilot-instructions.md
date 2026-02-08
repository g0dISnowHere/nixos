# GitHub Copilot Instructions (Repo-Scoped)

You are working in a modular NixOS flake repository.

## Core Principles
- Keep modules self-contained: include all related config in the same module file.
- Use explicit imports only (no recursive discovery).
- Prefer role modules for shared config; avoid machine-specific config in shared modules.
- Desktop environments are self-contained and import the shared desktop module: modules/nixos/desktop/common.nix.

## Fast Validation (Preferred)
- Use `nix eval` and `nix flake check` for quick validation; avoid `nixos-rebuild switch` for iteration.

## Layout (Short)
- Flake entry: flake.nix
- Orchestration: outputs.nix
- Flake outputs: flake/
- Reusable NixOS modules: modules/nixos/
- Home-Manager modules: modules/home/
- Machine configs: machines/

## Desktop Interchangeability
- Desktop selection is via `desktop` in mkNixosSystem.
- Shared desktop infrastructure lives in modules/nixos/desktop/common.nix.
- GNOME/Plasma specifics live in modules/nixos/desktop/gnome.nix and plasma.nix.
- Plasma home-manager settings live in modules/home/plasma/ via plasma-manager.

## Commit & Quality
- Pre-commit hooks run nix fmt and validate.sh.
- Keep commits focused and validated.
