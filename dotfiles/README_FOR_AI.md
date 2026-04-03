# README_FOR_AI

This file is the local AI guide for `dotfiles/`. Use it only for work inside
the `dotfiles/` subtree, alongside the repo-wide rules in `AGENTS.md`.

Treat these configs as behavioral infrastructure, not ad-hoc tweaks.

## Core principles
- Predictability over dynamic behavior.
- Deterministic placement via explicit rules.
- Stable workflow semantics matter more than cosmetic cleanup.
- Minimal diffs are preferred because small config changes can alter the lived
  desktop behavior.

## Required workflow
1. Read `dotfiles/docs/setup/niri-workflow.md` for intent and tiers.
2. Read `dotfiles/state/` to understand the workflow model.
3. Run `dotfiles/scripts/doctor.sh` before making changes.
4. Make minimal, explicit edits that preserve tier boundaries.
5. New features should be commented out by default.

## Guardrails
- Preserve tier comments and structure in configs.
- Avoid surprise rewrites or large refactors unless requested.
- Keep routing rules explicit and easy to audit.
- Add new automation only when it preserves predictability.
- Prefer minimal diffs over broad rewrites.

## Niri config quick reference (avoid re-research)
- Config file: `dotfiles/modules/compositor/niri/config.kdl` (symlinked to `~/.config/niri/config.kdl`).
- Keybinds live in the `binds {}` block. New binds should be commented out by default.
- Common action families:
  - View/Focus: `focus-column-left/right`, `focus-workspace-up/down`, `focus-workspace <n>`.
  - Window move: `move-column-left/right`, `move-window-to-workspace-up/down`.
  - Overview: `toggle-overview`.
- Input is compositor-level (can override system defaults):
  - Example:
    ```
    input {
      touchpad {
        tap
        dwt
      }
    }
    ```
