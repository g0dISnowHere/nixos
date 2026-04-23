# Dev Templates Maintenance Follow-Up

The root flake now exposes local project templates from `parts/templates.nix`,
with template bodies under `dev-templates/`.

## Follow-Up Questions

- Should `dev-templates/flake.nix` remain as a standalone maintenance flake, or
  should the root flake become the only interface?
- Should template metadata be deduplicated so descriptions are not maintained in
  both `dev-templates/flake.nix` and `parts/templates.nix`?
- Is a helper command such as `dvt` worth keeping once the normal
  `nix flake new --template` workflow is documented?

## Current Bias

Keep the nested flake for now because it provides a maintenance shell and a
local place to check the template collection. Revisit this only if metadata
drift becomes annoying.

Do not add a helper command unless day-to-day use shows that the standard Nix
commands are too verbose.
