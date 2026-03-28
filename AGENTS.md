# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix` declares inputs; `outputs.nix` wires flake-parts modules.
- `parts/` is the home for flake-parts per-system modules such as formatting, dev shells, packages, systems, and checks. Some of that wiring may still live inline in `outputs.nix` during refactors; prefer moving it into focused files rather than growing `outputs.nix`.
- `flake/` defines flake outputs, including machine sets and home-manager profiles.
- `modules/nixos/` contains reusable NixOS modules grouped by concern: `desktop/`, `roles/`, `services/`, `system/`, and `virtualisation/`.
- `modules/home/` contains reusable home-manager modules grouped by concern: `dconf/`, `desktop/`, `packages/`, `plasma/`, `programs/`, and `services/`.
- Keep AI tooling isolated in `modules/home/packages/ai-tools.nix`; keep package installs and any related notes/settings together there instead of mixing them back into the general package list.
- `nixos/machines/<hostname>/` stores host-specific configuration and hardware scans.
- Keep modules self-contained and imported explicitly. Do not add recursive module discovery.
- Prefer role modules for shared machine behavior and keep machine-specific logic out of shared modules.

## Architecture Rules
- Desktop environments are self-contained and should import shared desktop infrastructure from `modules/nixos/desktop/common.nix`.
- Desktop selection is driven through the flake machine definitions rather than ad hoc imports in unrelated modules.
- Keep home-manager configurations standalone from machine definitions unless the coupling is intentional and necessary. The current repo supports both standalone home-manager profiles under `flake/homes/` and machine-attached home-manager users where that is explicitly chosen.
- Treat Home Manager as a portable user-environment layer, not as a requirement to translate all dotfiles into Nix.
- Prefer a hybrid Home Manager model:
  - use Home Manager for packages, activation, user services, environment/session wiring, and symlinks into repo-managed dotfiles
  - keep most hand-maintained application config as normal files under `dotfiles/`
- If a config already exists as a stable file in `dotfiles/`, prefer linking it with `home.file` or `xdg.configFile` instead of rewriting it as Nix unless the Home Manager module is clearly better.
- Keep shared Home Manager modules portable. Do not hardcode personal identity, machine-local paths, or NixOS-only assumptions in reusable baseline modules unless the module is intentionally single-user or machine-specific.
- When adding shared functionality, place it in a focused module instead of growing machine files.
- Keep `mkNixosSystem` and similar helpers as orchestration layers. Do not turn them into opaque policy hubs that hide where behavior comes from.

## Build, Test, and Development Commands
- `sh setup.sh` configures git hooks and verifies the local Nix environment after cloning.
- `git config core.hooksPath .githooks` enables the repository pre-commit hooks manually.
- `nix develop` enters the dev shell with formatting and linting tools.
- `nix flake show` is the quick structure check.
- `nix flake check` validates the flake and should be used before larger changes land.
- Prefer fast evals during iteration:
  - `nix eval .#nixosConfigurations.centauri.config.system.build.toplevel`
  - `nix eval .#nixosConfigurations.mirach.config.system.build.toplevel`
  - `nix eval .#homeConfigurations."djoolz@workstation".activationPackage`
  - `nix eval .#homeConfigurations."djoolz@server".activationPackage`
- `sh validate.sh` runs the broader validation flow for NixOS and home-manager.
- Use `sh validate.sh --dconf2nix` only when intentionally regenerating `modules/home/dconf/dconf.nix`.
- Only deploy after evals and validation pass:
  - `sudo nixos-rebuild test --flake .#centauri`
  - `sudo nixos-rebuild switch --flake .#centauri`

## Coding Style & Naming Conventions
- Format with `nix fmt` (treefmt; currently `nixfmt`, `yamlfmt`, and `black`).
- Keep imports explicit and modules focused on one feature or responsibility.
- Hostnames map to folder names: `nixos/machines/<hostname>/default.nix`.
- Keep commits focused, lowercase, and descriptive, matching existing history.

## Testing & Validation
- There is no unit-test suite; rely on `nix eval`, `nix flake check`, and `sh validate.sh`.
- Prefer `nix eval` for fast feedback during development instead of full rebuilds.
- Pre-commit hooks in `.githooks/pre-commit` enforce formatting and validation before commits.

## Change Management
- Review `plan.md` when working on larger refactors, migrations, or structural changes.
- Review `plan-home-manager-dotfiles-strategy.md` when changing how home-manager and raw dotfiles are split.
- Preserve explicit structure and avoid reintroducing older mixed-concern layouts described in `plan.md`.
- If you add new machines or major module families, update this file so it remains the canonical agent guide.

## Agent-Specific Instructions
- Treat `AGENTS.md` as the canonical repository guidance for automated coding agents.
- `.github/copilot-instructions.md` contains a shorter companion summary; keep it consistent with this file when architecture rules change.
- Do not rely on `CLAUDE.md` or `GEMINI.md` containing separate guidance; they should resolve to this file.
