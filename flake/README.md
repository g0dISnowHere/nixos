# Flake Layer

The `flake/` directory is the composition layer of the repo. It is where the
main outputs are assembled from reusable modules and host definitions.

## Role

This layer should stay focused on orchestration:

- defining machine sets
- defining standalone Home Manager outputs
- carrying small helpers used to compose those outputs

It should describe how the system is assembled, not hide large amounts of
policy or implementation detail.

## Main Areas

- `machines/`
  - groups machine definitions by role
- `homes/`
  - standalone Home Manager outputs and profile composition
- `lib.nix`
  - helper functions used to wire machines and homes together

## Design Intent

Keep this layer readable. A person looking at `flake/` should be able to tell
how the repo is composed without chasing hidden behavior through opaque helper
logic.
