# Host Composition Uncommitted Review

**Date:** 2026-07-16
**Type:** Two-axis review of uncommitted changes
**Fixed point:** `HEAD` (`9f13303be94d2b971e72852b76eed9fe417e1bf1`)
**Diff command:** `git diff HEAD -- . ':(exclude)dev-templates/**'`
**Ignored scope:** `dev-templates/**` per user instruction

## Standards

No findings.

Grounding:
- Reviewed against `.github/copilot-instructions.md`, `README.md`, `docs/README.md`, `docs/architecture/capability-modules.md`, `docs/architecture/home-manager-dotfiles-strategy.md`, `scripts/README.md`, and `scripts/README_FOR_AI.md`.
- Current diff appears to be formatting/lint churn only.
- Spot checks on `modules/nixos/services/crowdsec.nix`, `modules/nixos/system/autoupgrade.nix`, and `modules/home/desktop/niri.nix` showed line wrapping, indentation, list splitting, and expression reshaping without behavioral edits.

## Spec

### 1. Missing core refactor work

Spec requires host-composition architecture changes, but current diff does not touch the key implementation files.

Spec evidence:
- `docs/future-ideas/host-composition-execution-plan.md:46-47` — "Put all host behavior selection in `nixos/machines/<host>/default.nix`."
- `docs/future-ideas/host-composition-execution-plan.md:57-68` — `flake/lib.nix` `mkNixosSystem` should drop `desktopEnvironment` / `enableHomeManager` ownership.
- `docs/future-ideas/host-composition-refactor-plan.md:47-48` — "Move per-host behavior selection out of `flake/machines/*.nix` into `nixos/machines/<host>/default.nix`."
- `docs/future-ideas/host-composition-refactor-plan.md:62-76` — `mkNixosSystem` should keep orchestration only.

Diff evidence:
- No changes in `flake/lib.nix`
- No changes in `flake/machines/*.nix`
- No changes in `nixos/machines/*/default.nix`

Assessment:
- Refactor requested by supplied plans is not present in uncommitted tree.

### 2. Scope creep: broad formatting pass unrelated to spec

Spec goal is architectural refactor, not repository-wide formatting.

Spec evidence:
- `docs/future-ideas/host-composition-execution-plan.md:5-7` — goal is to make host defaults canonical, reduce `flake/` to orchestration, remove role/UI shorthand.
- `docs/future-ideas/host-composition-refactor-plan.md:22-27` — target is canonical host definitions, explicit Home Manager per host, and no leaky desktop switch.

Diff evidence:
- 43 non-template files changed, `+811/-567`
- Touched files include unrelated formatting churn in `modules/`, `nixos/machines/*/{firewall,hardware-configuration,...}.nix`, `parts/checks.nix`, `pkgs/jjazzlab/default.nix`, `scripts/secrets-lib/render-sops-config.nix`, and `shell.nix`

Assessment:
- Current diff adds broad formatting noise without implementing requested host-composition cutover.

## Summary

- **Standards:** 0 findings
- **Spec:** 2 findings
- **Worst standards issue:** none
- **Worst spec issue:** requested host-composition refactor is absent from current diff
