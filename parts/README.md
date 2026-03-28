# Flake Parts

The `parts/` directory holds the flake-parts modules that shape per-system
tooling and developer ergonomics.

## Role

This layer is for flake plumbing and development support, not for machine
policy. It is where formatting, dev shells, checks, and similar per-system
features belong.

## Design Intent

Keeping these concerns in `parts/` makes the flake easier to reason about:

- machine architecture stays separate from developer tooling
- per-system concerns stay together
- `outputs.nix` can remain an orchestrator instead of a large mixed file
