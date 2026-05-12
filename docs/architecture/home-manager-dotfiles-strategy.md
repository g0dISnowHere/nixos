# Home Manager And Dotfiles

This note explains one core repo choice: user env is declarative, but not every
app config gets rewritten into Nix.

## Core Idea

Repo treats Home Manager as user-level integration layer, not replacement for
every normal config file.

Meaning:

- Home Manager owns user env as system
- `dotfiles/` owns most app-facing config content
- reusable layering stays in Nix; app-specific config can stay in native format

Result: reproducible system, less day-to-day editing pain.

## Architectural Boundary

Home Manager good for:

- packages
- activation logic
- session and environment wiring
- user services
- linking files into place

`dotfiles/` good for:

- compositor config
- launcher, notification, shell-facing app config
- UI assets and small helper scripts
- other config best maintained as plain files

## Why This Split Exists

Rewrite everything into Nix → uniform, often worse to maintain.
Declare nothing → harder to reproduce, harder to move machines.

Repo picks middle path:

- declare environment
- keep raw config raw
- keep connection explicit

## Main Areas

- [flake/homes/](../../flake/homes): profile composition, standalone Home Manager outputs
- [modules/home/](../../modules/home): reusable Home Manager modules by concern
- [dotfiles/](../../dotfiles): raw config content linked into place
- [nixos/machines/](../../nixos/machines): host attachment points when machine-local user wiring needed

## Live Checkout Path

Some Home Manager modules use `mkOutOfStoreSymlink` so linked files point at a
live checkout instead of a copied flake snapshot.

For that reason, the flake passes a `repoRoot` special argument into the Home
Manager layer and derives `dotfilesRoot` from it.

Resolution order:

- if `REPO_ROOT` is set in the evaluation environment, use that as the live
  checkout path
- otherwise fall back to the flake source path so pure evaluation still works

This avoids hardcoding one machine-local absolute path into the shared flake
while still allowing working-tree-backed links during local use.

## Design Rule

When deciding where thing lives, choose representation that keeps behavior
clear and maintenance burden low. Architecture matters more than forcing one
style everywhere.

## Related Files

- [docs/dotfiles/README.md](../dotfiles/README.md)
