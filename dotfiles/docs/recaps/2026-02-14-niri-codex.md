# Recap — 2026-02-14

Context: continued the Niri desktop workflow discussion and verified the repo
contains the `dotfiles/` layout, health checks, and docs for the desktop setup.

## Repo State Verified
- `dotfiles/` exists with: `docs/`, `state/`, `health/`, `modules/`, `scripts/`, and `README_FOR_AI.md`.
- Key files present:
  - `dotfiles/docs/setup/niri-workflow.md`
  - `dotfiles/state/workspace-map.md`
  - `dotfiles/state/app-rules.md`
  - `dotfiles/health/doctor.sh` + checks
- `dotfiles/modules/compositor/niri/config.kdl`
- `dotfiles/modules/ui/waybar/*`, `dotfiles/modules/ui/mako/*`
- `.github/copilot-instructions.md` and `CLAUDE.md` were read and followed.

## Current Implementation
### 1) Home Manager desktop wiring
The Niri desktop is managed through Home Manager:
- `modules/home/desktop/niri.nix`
  - declares the stable desktop links with `xdg.configFile`
  - links the repo-backed Niri, Nirinit, Waybar, Mako, Fuzzel, and Noctalia config
- `flake/homes/profiles/desktop.nix`
  - conditionally imports `modules/home/desktop/niri.nix` when `desktop == "niri"`

### 2) Niri desktop module check
Confirmed `modules/nixos/desktop/niri.nix` already exists and is selected via:
- `flake/lib.nix`: `desktop = "niri"` maps to `../modules/nixos/desktop/niri.nix`.
- `flake/machines/workstations.nix`: `centauri` uses `desktop = "niri"`.
No changes required to `modules/nixos/desktop/niri.nix`.

## Commands Run / Results
- `nix eval .#homeConfigurations."djoolz@workstation".activationPackage`
  - Result: success (derivation printed).
- Attempted `djoolz@centauri` eval:
  - Fails because `djoolz@centauri` is not defined in `flake.homeConfigurations`.
  - Valid targets currently: `djoolz@workstation`, `djoolz@server`.

## Activation Step
Run:
```
home-manager switch --flake .#djoolz@workstation
```
This activates the Home Manager desktop profile and establishes the managed
desktop links.
