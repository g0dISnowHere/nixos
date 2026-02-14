# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix` declares inputs; `outputs.nix` wires flake-parts modules.
- `parts/` holds per-system tooling (devshell, formatter, checks).
- `flake/` defines machine and home-manager outputs.
- `modules/nixos/` contains reusable system modules; `modules/home/` for home-manager.
- `nixos/machines/<hostname>/` stores host configs and hardware scans.
- Keep modules self-contained and imported explicitly (no recursive discovery).

## Build, Test, and Development Commands
- `sh setup.sh` — configure git hooks and verify the Nix environment after cloning.
- `nix develop` — enter the dev shell with linting/format tools.
- `nix flake show` — quick structure check; `nix flake check` for flake validation.
- Fast evals during iteration:
  - `nix eval .#nixosConfigurations.centauri.config.system.build.toplevel`
  - `nix eval .#homeConfigurations."djoolz@workstation".activationPackage`
- `sh validate.sh` — comprehensive validation (NixOS + home-manager); use `--dconf2nix` when updating dconf.
- Deployment (only after evals pass): `sudo nixos-rebuild test --flake .#centauri` or `switch`.

## Coding Style & Naming Conventions
- Format with `nix fmt` (treefmt; nixfmt + yamlfmt + black).
- Keep imports explicit and modules focused on a single feature.
- Hostnames map to folder names: `nixos/machines/<hostname>/default.nix`.

## Testing Guidelines
- No unit-test suite; rely on `nix eval`, `nix flake check`, and `sh validate.sh`.
- Validation is enforced by the pre-commit hook in `.githooks/pre-commit`.

## Commit & Pull Request Guidelines
- Commit messages in history are short, lowercase, and descriptive (e.g., “updates”, “new dconf.nix”).
- Ensure pre-commit hooks are enabled: `git config core.hooksPath .githooks`.
- Do not run `git commit` with `sudo` (hook blocks it).
- PRs should include: a brief summary, validation output (or commands run), and any affected hosts/modules.

## Agent-Specific Instructions
- Review `CLAUDE.md` and `.github/copilot-instructions.md` for architectural rules.
- Use `plan.md` when coordinating larger refactors or migrations.
