# Recap — 2026-02-14

Context: continued the niri desktop workflow discussion and verified the repo already contains the `dotfiles/` layout, health checks, and docs from the prior plan.

Note: this recap is historical. The current repo no longer uses
`home.activation` to run `dotfiles/scripts/link.sh` for the Niri desktop.
Home Manager now declares the relevant `xdg.configFile` links directly.

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

## Implementation Work
### 1) Home-manager wiring for dotfiles symlink script
Added a Home Manager module to run the existing `dotfiles/scripts/link.sh` during activation when `desktop == "niri"`:
- New file: `modules/home/desktop/niri.nix`
  - Uses `home.activation.linkNiriDotfiles` to run `dotfiles/scripts/link.sh`.
  - Assumes repo path: `~/Documents/01_config/mine/dotfiles`.
- Added conditional import in `flake/homes/profiles/desktop.nix`:
  - If `desktop == "niri"` then import `modules/home/desktop/niri.nix`.

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

## Current Activation Step (to apply)
Run:
```
home-manager switch --flake .#djoolz@workstation
```
This will execute `dotfiles/scripts/link.sh` and establish the `.config` symlinks.

## Open Questions / Next Options
- Add an alias `djoolz@centauri` home configuration (optional).
- If the repo path changes, update `modules/home/desktop/niri.nix`.
