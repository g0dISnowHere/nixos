# README_FOR_AI

This repository contains a deliberately structured desktop workflow for niri.
Treat these configs as infrastructure, not ad-hoc tweaks.

## Core principles
- Predictability over dynamic behavior.
- Deterministic placement via explicit rules.
- Incremental complexity through tiers.
- Configs should self-heal over time.

## Required workflow
1. Read `dotfiles/docs/setup/niri-workflow.md` for intent and tiers.
2. Read `dotfiles/state/` to understand the workflow model.
3. Run `dotfiles/health/doctor.sh` before making changes.
4. Make minimal, explicit edits that preserve tier boundaries.

## Guardrails
- Preserve tier comments and structure in configs.
- Avoid surprise rewrites or large refactors unless requested.
- Keep routing rules explicit and easy to audit.
- Add new automation only after the prior tier feels stable.
