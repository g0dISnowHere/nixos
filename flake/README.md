# Flake Layer

The `flake/` directory is composition layer of repo. It is where main outputs are
assembled from reusable modules and canonical host definitions.

## Role

This layer should stay focused on orchestration:

- registering concrete host setups
- defining standalone Home Manager outputs
- carrying small helpers used to compose those outputs

It should describe how system is assembled, not hide large amounts of policy or
implementation detail.

## Main Areas

- `machines/`
  - registers concrete host setups for flake outputs
- `homes/`
  - standalone Home Manager outputs and user-environment composition
- `lib.nix`
  - helper functions used to wire hosts and homes together

## Design Intent

Keep this layer readable. Person looking at `flake/` should be able to tell how
repo is composed without chasing hidden behavior through opaque helper logic.
Machine behavior should come from explicit capability module imports.
Repo-wide architecture guidance belongs in `docs/`; this README should stay
focused on role of `flake/` itself.
