# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix` declares inputs; `outputs.nix` wires flake-parts modules.
- `parts/` is the home for flake-parts per-system modules such as formatting, dev shells, packages, systems, and checks. Some of that wiring may still live inline in `outputs.nix` during refactors; prefer moving it into focused files rather than growing `outputs.nix`.
- `flake/` defines flake outputs, including machine sets and Home Manager profiles.
- `secrets/` holds SOPS-managed secret templates, examples, and encrypted files; keep shared secret layout explicit by scope (`users/`, `machines/`, `services/`) instead of scattering secret metadata through machine files.
- Organize by scope first, feature second.
- `modules/nixos/` contains reusable NixOS modules grouped by concern: `desktop/`, `flatpak/`, `services/`, `system/`, `users/`, and `virtualisation/`.
- `modules/home/` contains reusable Home Manager modules grouped by concern: `dconf/`, `desktop/`, `packages/`, `plasma/`, `programs/`, and `services/`.
- When a feature spans both NixOS and Home Manager, model it as two coordinated modules with different scopes: a system-level module for OS configuration and a user-level module for Home Manager state. Prefer names that make scope obvious; only reuse the same feature name across both layers when paths, option namespaces, and documentation already remove ambiguity.
- Keep AI tooling isolated in `modules/home/packages/ai-tools.nix`; keep package installs and any related notes/settings together there instead of mixing them back into the general package list.
- `nixos/machines/<hostname>/` stores host-specific configuration and hardware scans.
- Keep modules self-contained and imported explicitly. Do not add recursive module discovery.
- Prefer explicit capability modules for shared machine behavior and keep machine-specific logic out of shared modules. Do not reintroduce broad machine-role modules for shared policy.
- Keep shared secret plumbing in focused modules and keep concrete secret declarations close to their owning scope (shared user secrets under `secrets/users/`, host-only secrets under `secrets/machines/`, service secrets under `secrets/services/`).

## Architecture Rules
- Desktop selection is driven through the flake machine definitions rather than ad hoc imports in unrelated modules.
- Keep the system/user boundary explicit: NixOS modules choose and configure system-level behavior; Home Manager modules add user-level packages, services, settings, and dotfile links.
- Reuse of the same Home Manager profile across standalone Home Manager and NixOS-integrated Home Manager is fine because those are separate evaluations.
- Keep Home Manager configurations standalone from machine definitions unless the coupling is intentional and necessary. The current repo supports both standalone Home Manager profiles under `flake/homes/` and machine-attached Home Manager users where that is explicitly chosen.
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
  - `nix eval .#nixosConfigurations.albaldah.config.system.build.toplevel`
  - `nix eval .#homeConfigurations."djoolz@workstation".activationPackage`
- `sh validate.sh` runs the broader validation flow for NixOS and Home Manager.
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

## Documentation
- The repo uses explicit documentation types; do not treat all markdown as one flat docs bucket.
- Human canonical docs live in `README.md`, `docs/README.md`, and stable sections under `docs/`.
- Human reference docs are short lookup material such as command lists and checklists under `docs/reference/`.
- Incubator docs are non-canonical by default:
  - `docs/findings/` for dated investigations and point-in-time analysis
  - `docs/future-ideas/` for proposals, backlog items, and incomplete plans
- Local-area docs stay near the code they describe when they are scoped to one subtree, such as `dotfiles/` notes or directory READMEs.
- Keep enduring repository documentation under `docs/`; do not add new canonical repo docs elsewhere unless the file is an intentional entrypoint like `README.md`.
- Write canonical docs around stable concepts, ownership, and workflows rather than temporary refactor steps.
- Reference docs should optimize for retrieval speed, not explanation; keep them short and current.
- Update nearby docs when architecture, module boundaries, operator workflows, or doc taxonomy change.
- Review `docs/architecture/home-manager-dotfiles-strategy.md` when changing how Home Manager and raw dotfiles are split.
- Update `docs/README.md` when adding a new documentation area, changing the taxonomy, or promoting incubator material into canonical docs.

## Change Management
- Move incomplete plans and proposals into `docs/future-ideas/` rather than leaving them mixed with canonical documentation.
- Preserve explicit structure and avoid reintroducing older mixed-concern layouts.
- If you add new machines or major module families, update this file so it remains the canonical agent guide.

## Agent-Specific Instructions
- Treat `AGENTS.md` as the canonical repository guidance for automated coding agents.
- `.github/copilot-instructions.md` is a short companion mirror; keep it consistent with this file and avoid letting it become a second source of truth.
- Do not rely on `CLAUDE.md` or `GEMINI.md` containing separate guidance; they should resolve to this file.
- Local-area AI docs may exist for subtree-specific implementation rules, but
  they must stay scoped and must not override repo-wide guidance in
  `AGENTS.md`.
- When working under `scripts/`, review `scripts/README.md` for operator-facing
  structure and `scripts/README_FOR_AI.md` for subtree-local implementation
  guidance.
