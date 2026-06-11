# AI notes for `dev-templates/`

- Templates are devenv-based.
- Keep legacy `flake.nix` files as preserved reference material unless explicitly asked to remove them.
- Do not reintroduce per-template flake dev shells as the active entrypoint unless explicitly requested.
- Keep `.envrc` loading devenv direnv support, then calling `use devenv`.
- Keep `devenv.nix` as the active shell definition for migrated templates.
