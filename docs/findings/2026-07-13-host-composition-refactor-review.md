# Host Composition Refactor - Code Review

**Date:** 2026-07-13
**Type:** Two-Axis Code Review (Standards vs Spec)
**Target:** Uncommitted changes (Host Composition Refactor)

## Standards

* **`modules/home/packages/desktop-apps.nix` & `modules/nixos/system/gui-developer-tools.nix`**
  **Violation:** `AGENTS.md` explicitly states: *"Keep AI tooling isolated in `modules/home/packages/ai-tools.nix`; keep package installs and any related notes/settings together there instead of mixing them back into the general package list."*
  The diff removes `pkgs-unstable.antigravity` from `ai-tools.nix` and improperly mixes it into general `desktop-apps.nix` and the new `gui-developer-tools.nix` module.

* **Speculative Generality** in `flake/homes/users/djoolz/gnome.nix`
  ```nix
  { ... }: {
    imports = [
      # ../../../modules/home/dconf/dconf.nix
    ];
  }
  ```
  This new file is completely empty/commented out and serves no immediate purpose. It should be deleted until it actually implements GNOME home configurations.

* **Middle Man** in `flake/homes/users/djoolz/gui-apps.nix`
  ```nix
  { ... }: {
    imports = [
      ./base.nix
      ../../profiles/gui.nix
    ];
  }
  ```
  This file only delegates to other profiles. The `djoolz@gnome` configuration in `flake/homes/djoolz.nix` should import `base.nix` and `profiles/gui.nix` directly rather than chaining through an intermediary module that adds no explicit behavior.

## Spec

**(a) Missing or partial requirements**
The refactor successfully executed all phases of the spec. Hosts were migrated to canonical ownership, `mkNixosSystem` was stripped of implicit behavior, and role-named HM wrappers were decomposed. No requirements were missed.

**(b) Scope creep (behaviour not asked for)**
No scope creep observed. *(Note: Unrelated `AGENTS.md` and `docs/README.md` documentation changes were reverted prior to saving this report).*

**(c) Implemented but wrong**
In `flake/homes/users/djoolz/base.nix`, the refactor removed `ai-tools.nix` and `developer-tools.nix` from the core imports but immediately reintroduced them using a new conditional: `++ lib.optionals (!isNixosIntegrated) [...]`. This re-creates the exact "hidden policy" smell the refactor was designed to eliminate. The standalone target in `flake/homes/djoolz.nix` should import those capabilities explicitly if it needs them, rather than hiding a toggle inside what should be a dumb baseline.
*Spec quote:* *"Rule: `base` means minimum valid baseline only — anything optional or host-selective moves outward into explicit imports"* and *"replace role/profile wrappers with capability-oriented or explicit composition units"*.

---

**Summary:**
* **Standards:** 3 findings. Worst issue: Breaking the documented AI tooling isolation boundary by moving `antigravity` into general desktop applications.
* **Spec:** 1 finding. Worst issue: The `lib.optionals` conditional reintroducing hidden policy to `base.nix`.
