# Home Manager Dotfiles Strategy

## Status

This document records the current Home Manager and dotfiles architecture in
this repository.

## Goal

Use Home Manager as a portable user-environment layer without translating all
dotfiles into Nix.

The intended outcome is:

- Keep most real configuration as normal files in `dotfiles/`
- Use Home Manager to install packages, enable user programs and services, and
  link dotfiles into place
- Keep the setup reusable on NixOS and non-NixOS Linux systems
- Avoid turning Home Manager into a second full configuration language for
  every application

## Current Decision

This repo uses a hybrid model:

- Home Manager owns package installation, user session wiring, user services,
  and symlinks into repo-managed dotfiles
- Raw dotfiles remain the source of truth for most hand-maintained application
  and desktop config
- Configuration is only expressed in Nix when it clearly improves
  repeatability, portability, or integration

## What Is Implemented

### 1. Shared vs Personal Home Manager Layers

The reusable base profiles live under `flake/homes/profiles/`.

- `flake/homes/profiles/common.nix` contains the shared portable baseline
- `flake/homes/profiles/desktop.nix` extends it for GUI systems

User-specific layering lives under `flake/homes/users/djoolz/`.

- `flake/homes/users/djoolz/common.nix`
- `flake/homes/users/djoolz/desktop.nix`
- `flake/homes/users/djoolz/personal.nix`

This keeps personal identity details out of reusable baseline modules.

### 2. Dotfiles Remain the Canonical Config Content

The `dotfiles/` tree remains the canonical source for hand-maintained desktop
config, including Niri-related files.

Home Manager is now the canonical deployment mechanism for stable desktop links
such as:

- `niri`
- `nirinit`
- `waybar`
- `mako`
- `fuzzel`
- `noctalia`

Those links are declared in `modules/home/desktop/niri.nix`.

### 3. Repo Paths Are Centralized

The flake wires `repoRoot` and `dotfilesRoot` through `extraSpecialArgs`
instead of scattering hardcoded repo paths through Home Manager modules.

This is done in:

- `flake/lib.nix`
- `flake/homes/djoolz.nix`

### 4. Shell and Developer Environment Are Separated

The interactive shell UX now lives in Home Manager:

- `modules/home/programs/shell.nix`

It owns:

- Zsh user experience
- `fzf`
- `zoxide`
- shell aliases
- history settings
- shell-focused CLI tools

The user-scoped developer environment also lives in Home Manager:

- `modules/home/programs/developer-tools.nix`

It owns:

- Go, Python, Node, and Rust developer toolchains
- build utilities
- user-scoped developer session variables and path additions

On the NixOS side, shell handling is now intentionally minimal:

- `modules/nixos/system/login-shell.nix`

It only ensures that:

- `zsh` is the default login shell
- `programs.zsh.enable = true` is set for NixOS correctness

### 5. Broad Package Aggregation Was Split By Domain

The former `modules/home/packages/packages.nix` dumping ground has been removed.

Package domains are now split into focused modules:

- `modules/home/packages/fonts-and-docs.nix`
- `modules/home/packages/system-utils.nix`
- `modules/home/packages/nix-tools.nix`
- `modules/home/packages/desktop-apps.nix`
- `modules/home/packages/maker-tools.nix`
- `modules/home/packages/ai-tools.nix`

This keeps package ownership explicit and avoids reintroducing a single broad
package bucket.

Desktop-only package domains are imported from `flake/homes/profiles/desktop.nix`
instead of the portable common baseline. `modules/home/packages/nautilus.nix`
is attached explicitly to the Niri desktop path.

### 6. Home Manager Backup Handling Was Upgraded

The repo now uses a custom `home-manager.backupCommand` in `flake/lib.nix`
instead of relying on a fixed backup extension.

Current behavior:

- conflicting files are moved into
  `~/.local/state/home-manager-backups`
- backups are timestamped
- backups older than 30 days are pruned automatically
- empty directories are cleaned up

This is intended to minimize friction during repeated updates.

## Current Layering Model

### Portable Base Profile

File: `flake/homes/profiles/common.nix`

Responsibilities:

- shared Home Manager imports
- portable package domains
- shell UX and developer environment modules
- base home-manager state version

### Desktop Profile

File: `flake/homes/profiles/desktop.nix`

Responsibilities:

- desktop-specific imports
- desktop-only services
- desktop-specific dotfile links
- conditional DE-specific modules

### Focused Home Modules

Files under `modules/home/`

Responsibilities:

- program enablement
- shell UX
- developer tools
- package domains
- desktop link management
- small reusable services

### Dotfiles Tree

Files under `dotfiles/`

Responsibilities:

- hand-maintained config files
- desktop and compositor config
- supporting scripts
- docs and state files for desktop workflows

## Preferred Integration Rules

### Link Existing Files First

If a config already exists as a stable file in `dotfiles/`, prefer linking it
with `home.file` or `xdg.configFile` instead of rewriting it into Nix.

### Keep Shared Modules Portable

Reusable Home Manager modules should not hardcode:

- user identity
- machine-local paths
- NixOS-only assumptions

unless they are intentionally user-specific or machine-specific.

### Keep System vs User Boundaries Honest

NixOS modules should describe machine-wide behavior.

Home Manager modules should describe:

- user shell behavior
- user developer environment
- user packages
- user services
- user session environment

### Avoid Reintroducing Aggregator Dumps

Do not recreate broad mixed-concern files like the removed
`modules/home/packages/packages.nix`.

If a package area grows, split it by responsibility instead.

## Completed Phases

### Completed Phase 1

- Removed hardcoded git identity from shared Home Manager baseline modules
- Centralized repo path and dotfiles path wiring
- Updated repo guidance to document the hybrid Home Manager model

### Completed Phase 2

- Added user-specific wrapper profiles
- Moved personal git identity into a dedicated personal module
- Replaced Niri activation-script deployment with explicit Home Manager-managed
  links

### Completed Phase 3

- Reduced remaining NixOS-side path coupling
- Replaced fixed Home Manager backup suffix handling with a timestamped
  `backupCommand`

### Completed Follow-On Cleanup

- Split login-shell handling from user shell UX
- Moved developer environment into Home Manager user space
- Split the broad package list into explicit domains

## Personal Config Policy

Additional personal config should stay raw-file-based by default. Use a small
Home Manager module only when the setting is stable, structured, and gains
clear value from package or session integration.

Current policy:

- Git uses a hybrid approach:
  Home Manager owns enablement and identity, while hand-edited extras live in
  `dotfiles/git/config.inc`.
- Editor config stays raw-file-based.
- Tmux config stays raw-file-based.
- SSH config should be decided case by case; use Home Manager only if a small
  structured host setup becomes useful.

## Success Criteria

This strategy is working if:

- a new Linux machine can get the desired user environment with minimal manual
  setup
- most personal configs remain plain files
- Home Manager modules stay focused and readable
- the same repo can support NixOS and standalone Home Manager usage
- there is no pressure to rewrite every config file in Nix

## Anti-Goals

Do not:

- rewrite all dotfiles into Home Manager modules
- create recursive config discovery for home modules
- duplicate the same configuration as both raw files and generated Nix
- hardcode personal identity or machine-local assumptions into reusable shared
  modules
- reintroduce large mixed-concern package or shell modules

## Summary

Home Manager in this repo is a portable user-environment layer wrapped around a
dotfiles-first workflow.

The dotfiles remain the canonical hand-maintained config content. Home Manager
provides the reproducible glue: package installation, shell and developer
environment setup, user services, and stable deployment links into those
dotfiles.
