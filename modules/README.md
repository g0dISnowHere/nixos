# Modules

The `modules/` directory contains the reusable building blocks of the repo.
This is where shared behavior lives once it stops being specific to a single
host or user profile.

## Split

- `nixos/`
  - reusable machine and system modules
- `home/`
  - reusable Home Manager modules

## Design Intent

Modules should express focused concerns and be imported explicitly. This keeps
shared behavior visible and prevents host files from turning into large,
duplicated policy bundles. Repo-wide architecture explanation belongs in
`docs/`; this README should stay scoped to `modules/`.
