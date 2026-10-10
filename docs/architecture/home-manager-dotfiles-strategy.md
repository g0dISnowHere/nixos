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

## App-Written Portable Settings

Selected app-written files have a separate mutable chezmoi source in the private
`g0dISnowHere/dotfiles` repository. Home Manager installs its tools and guarded
user timer; sops-nix provisions credentials. Every importing host receives the
same managed plain-file targets. Secret templates are selected from each
destination's declared runtime-secret dependencies, not a hostname or desktop
registry. Unavailable undeclared optional credentials exclude only their own
targets; a provisioned secret missing at runtime stops writes visibly. This does
not erase credential files already rendered before provisioning is removed.
Same-target collisions preserve both edits for manual reconciliation.

This does not replace existing `dotfiles/` links or enroll whole application
profiles. Each migrated destination loses its previous file owner. A newly
configured host can bootstrap the private source on its first five-minute timer
run, subject to authentication, app-writer guards, and conflict checks. See the
[chezmoi runbook](../reference/chezmoi.md) for target ownership, secret selection,
onboarding, synchronization checks, and backup/recovery behavior.

On first enrollment, a native target already matching the fetched source is not
rewritten; an active application on that unchanged target does not block other
missing settings. A divergent native target stops onboarding before other writes
or the applied-revision marker.

## Related Files

- [docs/dotfiles/README.md](../dotfiles/README.md)
