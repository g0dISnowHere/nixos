# Dotfiles

`dotfiles/` = plain-file layer. App and desktop config stay in native format,
still versioned, still wired into declarative setup.

This page = canonical note for how `dotfiles/` fit repo.

## Role In Architecture

This tree not second module system. Not junk pile. It holds config easier to
maintain as normal files than Nix.

Common examples:

- desktop and compositor config
- launcher, notification, shell-adjacent config
- UI assets and small helper scripts
- state or workflow refs useful near config

## Main Areas

- `modules/`: raw app and desktop config
- `scripts/`: helper scripts for dotfiles layer
- `state/`: workflow and reference state files
- `docs/`: dotfile-specific notes

## Design Intent

Point of `dotfiles/`: keep editing smooth where direct file edit best. Home
Manager links files into wider user env, not replace them all.

## Related Docs

- [docs/architecture/home-manager-dotfiles-strategy.md](../architecture/home-manager-dotfiles-strategy.md)
- [dotfiles/](../../dotfiles)
