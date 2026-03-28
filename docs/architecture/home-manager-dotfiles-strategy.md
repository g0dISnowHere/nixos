# Home Manager And Dotfiles

This note explains one of the main architectural choices in the repo: the user
environment is declarative, but not every application config is rewritten into
Nix.

## Core Idea

The repo treats Home Manager as the user-level integration layer, not as a
replacement for every normal config file.

That means:

- Home Manager is responsible for the user environment as a system
- `dotfiles/` is responsible for most application-facing config content
- reusable layering stays in Nix, while app-specific config can remain in the
  format the app already uses

This keeps the system reproducible without making day-to-day editing more
awkward than necessary.

## Architectural Boundary

Home Manager is the right place for:

- packages
- activation logic
- session and environment wiring
- user services
- linking files into place

`dotfiles/` is the right place for:

- compositor config
- launcher, notification, and shell-facing app config
- UI assets and small helper scripts
- other config that is naturally maintained as plain files

## Why This Split Exists

If everything is rewritten into Nix, the system becomes more uniform but often
less pleasant to maintain. If nothing is declared, the setup becomes harder to
reproduce and move between machines.

This repo chooses the middle ground:

- declare the environment
- keep raw config raw
- keep the connection between the two explicit

## Main Areas

- [flake/homes/](../../flake/homes)
  - profile composition and standalone Home Manager outputs
- [modules/home/](../../modules/home)
  - reusable Home Manager modules by concern
- [dotfiles/](../../dotfiles)
  - raw config content that gets linked into place
- [nixos/machines/](../../nixos/machines)
  - host attachment points when machine-local user wiring is needed

## Design Rule

When deciding where something should live, prefer the representation that keeps
the behavior clear and the maintenance burden low. The architecture matters more
than forcing a single style everywhere.

## Related Files

- [docs/dotfiles/README.md](../dotfiles/README.md)
