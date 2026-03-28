# Dotfiles

The `dotfiles/` tree is the repo’s plain-file layer. It exists so application
and desktop config can stay close to the formats those programs already use,
while still being versioned and wired into the declarative environment.

## Role In The Architecture

This tree is not a second module system and not a dumping ground. Its role is
to hold the config that is easier to maintain as normal files than as Nix
expressions.

In practice, that usually means:

- desktop and compositor config
- launcher, notification, and shell-adjacent config
- UI assets and small supporting scripts
- state or workflow references that are useful to keep alongside the config

## Main Areas

- `modules/`
  - raw application and desktop config
- `scripts/`
  - helper scripts tied to the dotfiles layer
- `state/`
  - workflow and reference state files
- `docs/`
  - dotfile-specific supporting notes

## Design Intent

The point of `dotfiles/` is to keep the repo frictionless where direct editing
is the better experience. Home Manager then gives those files a clean place in
the larger user environment instead of replacing them outright.

## Related Docs

- [docs/architecture/home-manager-dotfiles-strategy.md](../architecture/home-manager-dotfiles-strategy.md)
- [dotfiles/](../../dotfiles)
