# Validation Flow Regressions

## Context
- Date: `2026-05-09`
- Scope: repo validation flow after the lint/check script split
- Affected files:
  - `parts/checks.nix`
  - `parts/devshells.nix`
  - `scripts/validate.sh`
  - `scripts/validate-fast.sh`

## Issue 1: `git ls-files` inside Nix checks
- Location: `parts/checks.nix` around lines `98-137`
- Problem: the `statix` and `deadnix` checks shell out to `git ls-files` from inside `pkgs.runCommand`.
- Impact: the derivation sees a store copy of the repo, not a working tree with `.git`, so the file list lookup fails in the Nix sandbox.
- Result: `nix flake check` and any CI path that evaluates these checks abort before the lints run.
- Fix direction: derive the Nix file list from build-time inputs that are available in the store, or move the file enumeration outside the sandbox.

## Issue 2: `shellcheck` missing from the default dev shell
- Location: `parts/devshells.nix` around lines `5-12`
- Problem: the new validation scripts call `scripts/lint-shell.sh`, but the default `nix develop` shell does not install `shellcheck`.
- Impact: the documented local workflow now depends on a tool that is not on `PATH`, so `sh validate.sh` and `sh scripts/validate-fast.sh` fail unless `shellcheck` is installed separately.
- Fix direction: add `shellcheck` to `devShells.default`, or make the shell lint script self-contained with an explicit tool path.

## Notes
- The new validation scripts are fine as an integration point.
- The regressions are in the wiring around them, not in the lint scripts themselves.
