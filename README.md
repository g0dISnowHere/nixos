# NixOS Configuration

This repo is a modular NixOS flake built around explicit machine definitions,
focused reusable modules, a standalone workstation Home Manager profile, and a
dotfiles-first user environment model. If you are new to NixOS, the official starting points
are the [NixOS Manual](https://nixos.org/manual/nixos/stable/) and the
[Nix language reference](https://nix.dev/manual/nix/2.28/language/).

It is opinionated about structure, but meant to stay soft in day-to-day use:
once the system and user environment are set up, Nix should mostly stay in the
background while packages, services, and developer tooling are already there.

If you are new to this repo, the short version is:

- Nix flakes define the machines and user environments
- NixOS modules describe shared system behavior
- Home Manager modules describe shared user behavior
- `dotfiles/` keeps most hand-maintained application config as normal files
- `docs/` explains how the pieces fit together

## What This Repo Optimizes For

- ease of use
  - common packages, services, and user setup should already be there
- flexibility
  - machine-specific behavior stays local, shared behavior stays reusable
- low friction
  - Home Manager handles wiring and activation without forcing every app config
    to be rewritten in Nix
- fast onboarding
  - a dev shell and flake outputs make it quick to inspect, validate, and work
    on the repo
- reproducibility where it matters
  - systems, user environments, and secrets can be rebuilt consistently

## At A Glance

- flake-parts based layout
- explicit machine definitions under `flake/machines/`
- reusable NixOS modules under `modules/nixos/`
- reusable Home Manager modules under `modules/home/`
- raw config files kept under `dotfiles/`
- human-facing docs centralized under `docs/`

## Current Scope

### NixOS Hosts

- `centauri`
  - primary workstation
- `mirach`
  - homelab machine
- `albaldah`
  - headless VPS

### Home Manager Outputs

- `djoolz@workstation`
  - desktop-oriented standalone profile

## Main Tools

- `nix`
  - evaluates, builds, and checks the flake
- `nixos-rebuild`
  - applies a NixOS system configuration to a machine
- `home-manager`
  - applies the standalone workstation user environment configuration
- `flake-parts`
  - structures the flake outputs into smaller modules
- `sops-nix`
  - manages encrypted secrets in NixOS
- `disko`
  - defines disk layout declaratively for installs such as `albaldah`
- `nixos-anywhere`
  - installs a NixOS machine remotely over SSH
- `treefmt` / `nix fmt`
  - keeps formatting consistent
- `validate.sh`
  - quick repo-specific validation wrapper

## Layout

```text
.
├── flake.nix / outputs.nix     # flake entrypoints
├── parts/                      # flake-parts modules
├── flake/                      # machine sets, HM outputs, helpers
├── modules/
│   ├── nixos/                  # reusable NixOS modules
│   └── home/                   # reusable Home Manager modules
├── nixos/machines/             # host-specific configuration
├── dotfiles/                   # raw config content linked into place
└── docs/                       # human-facing documentation
```

## How It Is Organized

- shared machine behavior belongs in reusable modules
- host-specific behavior belongs in `nixos/machines/<hostname>/`
- desktop and application config lives primarily in `dotfiles/`
- Home Manager is used for packages, activation, services, and link management
- documentation is split between lightweight overviews in `docs/` and detailed
  investigations in `docs/findings/` and `docs/future-ideas/`
- the goal is not to force everything into Nix, but to make the useful parts
  reproducible while keeping the system comfortable to work in

## Getting Started

If you just want to understand the repo:

1. Read [docs/README.md](docs/README.md).
2. Look at [flake/machines/workstations.nix](flake/machines/workstations.nix)
   and [flake/machines/homelabs.nix](flake/machines/homelabs.nix).
3. Check [modules/nixos/](modules/nixos) and [modules/home/](modules/home) for
   reusable building blocks.
4. Check [dotfiles/](dotfiles) for the raw config files that Home Manager links
   into place.

If you want to work on the repo:

```bash
nix develop
```

That gives you the main formatting and linting tools used in this repo.

The development shell is meant to be quick and practical: open it, inspect the
flake, run checks, and start working without manual tool setup first.

## Useful First Commands

If this is your first time looking at a Nix flake repo, these are the most
useful commands to start with:

```bash
nix flake show
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
nix eval .#homeConfigurations."djoolz@workstation".activationPackage
nix develop
```

What they do:

- `nix flake show`
  - shows the main outputs the flake provides
- `nix eval ...`
  - checks that a machine or Home Manager config evaluates without building it
- `nix develop`
  - opens the repo development shell with the main tools preloaded

## Validation

Use fast evals during iteration:

```bash
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
nix eval .#nixosConfigurations.mirach.config.system.build.toplevel
nix eval .#nixosConfigurations.albaldah.config.system.build.toplevel
nix eval .#homeConfigurations."djoolz@workstation".activationPackage
```

Broader checks:

```bash
nix flake check
sh validate.sh
```

When you are ready to apply a machine config locally, the basic NixOS command is:

```bash
sudo nixos-rebuild switch --flake .#centauri
```

## Where To Read More

- [docs/README.md](docs/README.md)
  - documentation index
- [docs/architecture/home-manager-dotfiles-strategy.md](docs/architecture/home-manager-dotfiles-strategy.md)
  - Home Manager and dotfiles split
- [docs/vps/README.md](docs/vps/README.md)
  - VPS documentation area
