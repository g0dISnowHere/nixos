# Home Manager Dotfiles Strategy

## Goal

Use Home Manager as a portable user-environment layer without translating all
dotfiles into Nix.

The intended outcome is:

- Keep most real configuration as normal files in `dotfiles/`
- Use Home Manager to install packages, enable user programs/services, and link
  dotfiles into place
- Keep the setup reusable on NixOS and non-NixOS Linux systems
- Avoid turning Home Manager into a second full configuration language for every
  application

## Decision

Adopt a hybrid model:

- Home Manager owns bootstrap, activation, linking, package sets, and selected
  structured program settings
- Raw dotfiles remain the source of truth for most interactive tools and
  desktop-facing configuration
- Only move configuration into Nix when Nix clearly improves portability,
  repeatability, or integration

## Why This Fits This Repo

This repository already prefers:

- explicit imports
- focused modules
- standalone home-manager profiles
- machine-independent reuse where practical

It also already contains a useful precedent in
`modules/home/desktop/niri.nix`, where Home Manager is used to activate or link
dotfiles rather than re-expressing the compositor config in Nix.

This strategy keeps that direction and makes it the default.

## Scope Boundaries

### Home Manager Should Own

- `home.packages`
- shell/session environment variables
- enabling portable user programs such as `git`, `direnv`, `ssh`, `gpg-agent`,
  `tmux`, and similar tools
- user services and timers
- activation hooks
- symlinks from the home directory into repo-managed dotfiles
- a small number of declarative program configs where the module is clearly
  better than a raw file

### Home Manager Should Usually Not Own

- large hand-maintained editor configs
- frequently edited desktop or compositor configs
- app state or machine-local state
- raw dotfiles that are easier to review and maintain as files
- complex application configs that would become verbose or awkward in Nix

## Layering Model

### 1. Portable Base Profile

File: `flake/homes/profiles/common.nix`

Responsibility:

- base home-manager state version
- shared imports
- portable packages
- shell/session defaults
- cross-machine CLI tools
- shared dotfile links

This profile should work on any Linux machine where Home Manager is available.

### 2. Desktop Profile

File: `flake/homes/profiles/desktop.nix`

Responsibility:

- GUI-only packages and services
- desktop-specific dotfile links
- desktop-specific activation hooks
- conditional imports for DE-specific helpers

This profile extends the base profile and remains reusable across NixOS and
standalone Home Manager use.

### 3. Focused Home Modules

Files under `modules/home/`

Responsibility:

- package groups
- portable program enablement
- small reusable service modules
- activation helpers
- selective declarative program configuration

These modules should stay narrow. They should not become a dumping ground for
all personal dotfiles expressed in Nix syntax.

### 4. Dotfiles Tree

Files under `dotfiles/`

Responsibility:

- plain config files
- scripts
- editor/compositor/terminal configs
- any configuration that is easier to keep as normal files

The `dotfiles/` tree should remain the primary source of truth for hand-edited
configs.

## Preferred Integration Methods

Use these in order of preference.

### 1. Link Existing Files

Use `home.file` or `xdg.configFile` to link repo-managed dotfiles into place.

Example:

```nix
{
  xdg.configFile."git/config".source = ../../../dotfiles/git/config;
  xdg.configFile."tmux/tmux.conf".source = ../../../dotfiles/tmux/tmux.conf;
  home.file.".zshrc".source = ../../../dotfiles/zsh/.zshrc;
}
```

Use this when:

- the file already exists
- the file is hand-maintained
- Nix would only add verbosity

### 2. Use Activation Hooks for Complex Linking or Setup

Use `home.activation` when linking is conditional, multi-step, or script-driven.

This is already the pattern used by `modules/home/desktop/niri.nix`.

Use this when:

- multiple files are linked together
- the setup is easier to express in shell than in HM file declarations
- an app expects a specific directory layout

### 3. Use Declarative HM Options Selectively

Use Home Manager native options only where they are clearly better.

Good candidates:

- `programs.git`
- `programs.direnv`
- `programs.ssh`
- `services.*`
- environment/session variables

Use this when:

- the module is stable and concise
- the generated config is easier to reason about than a raw file
- the feature integrates directly with package installation or services

## Repo-Specific Rules

### 1. Dotfiles First

If a config already exists as a usable file in `dotfiles/`, prefer linking it
instead of rewriting it in Nix.

### 2. Nix For Bootstrap, Not For Everything

Default to Home Manager for:

- installation
- activation
- service wiring
- path/session setup
- symlink management

Do not default to expressing every app config as Nix data.

### 3. Split Shared vs Personal Identity

Shared modules should not hardcode user identity details unless the module is
explicitly personal and single-user by design.

Current issue:

- `modules/home/programs/programs.nix` hardcodes git identity values

Preferred direction:

- keep `programs.git.enable = true` in shared baseline
- move user identity to a dedicated personal module or linked git config file

### 4. Keep Cross-Platform Assumptions Small

Avoid embedding NixOS-specific assumptions in reusable Home Manager modules
unless the module is explicitly NixOS-only.

### 5. Keep Machine-Specific Paths Isolated

If a module depends on a path like
`~/Documents/01_config/mine/dotfiles`, either:

- document that the repo location is intentional and fixed, or
- centralize the repo root path in one variable passed through
  `extraSpecialArgs`

This prevents path logic from spreading across multiple modules.

## Recommended Near-Term Refactor

### Phase 1: Keep Current Model, Reduce Friction

1. Leave most configs as files under `dotfiles/`
2. Continue using HM for package installation and activation
3. Replace hardcoded personal identity in shared program modules
4. Add explicit `home.file` and `xdg.configFile` links for stable dotfiles that
   should always be present

### Phase 2: Separate Concerns More Cleanly

1. Create a small personal module for identity and machine-independent user
   preferences
2. Keep `common.nix` focused on portable baseline behavior
3. Keep `desktop.nix` focused on GUI additions and desktop activation
4. Move any mixed program settings that are really file-backed into the
   `dotfiles/` tree

### Phase 3: Only Nixify What Earns It

Consider native Home Manager configuration only for tools where:

- the module is mature
- the configuration is small
- the declarative form is easier than maintaining raw files

Potential candidates:

- git defaults
- ssh host blocks if they benefit from generated structure
- direnv integration
- user services and timers

## Example Ownership Split

### Keep As Dotfiles

- `zsh` config
- `tmux` config
- editor config
- `niri` config
- terminal theme/config
- custom scripts

### Likely Keep In Home Manager

- package lists
- `direnv` enablement
- `git` enablement
- `gpg-agent` or `ssh-agent` setup
- `systemd.user` services
- desktop-independent environment variables
- links into `dotfiles/`

## Success Criteria

This strategy is working if:

- a new Linux machine can get the desired user environment with minimal manual
  setup
- most personal configs remain plain files
- Home Manager modules stay short and readable
- the same repo can support NixOS and standalone Home Manager usage
- there is no pressure to rewrite every config file in Nix

## Anti-Goals

Do not:

- rewrite all dotfiles into Home Manager modules
- create recursive config discovery for home modules
- duplicate the same configuration as both raw files and generated Nix
- hardcode personal identity and machine-specific assumptions into every shared
  module

## Proposed First Concrete Changes

1. Remove hardcoded git identity from `modules/home/programs/programs.nix`
2. Add a dedicated module or linked file for personal git identity
3. Add direct `home.file` or `xdg.configFile` links for any stable dotfiles not
   already managed by the Niri link script
4. Consider centralizing the repo root or dotfiles root path if more modules
   start referencing it

## Summary

Home Manager should be treated here as a portable activation and user
environment layer, not as a mandate to translate all dotfiles into Nix.

The repository should remain dotfiles-first, with Home Manager providing the
reproducible glue around those files.
