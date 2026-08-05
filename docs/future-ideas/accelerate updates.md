- devenv should only auto update on rebuild in this repo. Not good if `git pull` causes it to update and download dependencies.

- [general skills](https://github.com/Mic92/mics-skills)
- [direnv-instant](https://github.com/Mic92/direnv-instant): Non-blocking direnv integration daemon with tmux support that provides instant shell prompts by running direnv asynchronously in the background.
- [nix fast update](https://github.com/Mic92/fast-flake-update)
- [fast gc](https://github.com/Mic92/fast-nix-gc)
- [flake linter](https://github.com/Mic92/flake-linter): Find duplicate dependencies.

## Plan: add [nix-fast-build](https://github.com/Mic92/nix-fast-build)

1. Add `nix-fast-build` as a flake input in `flake.nix` (follow `nixpkgs` where possible).
2. Expose it in the repo devenv (`devenv.nix`) so it is available during local iteration.
3. Add a shell alias (e.g. `fcheck`) in `devenv.nix` that runs `nix-fast-build` against key targets:
   - `.#nixosConfigurations.centauri.config.system.build.toplevel`
   - `.#nixosConfigurations.mirach.config.system.build.toplevel`
   - `.#nixosConfigurations.albaldah.config.system.build.toplevel`
   - `.#homeConfigurations."djoolz@workstation".activationPackage`
4. Optionally add a dedicated package/wrapper in `parts/packages.nix` (only if alias-only flow is not enough).
5. Validate:
   - `nix flake lock --update-input nix-fast-build`
   - `devenv shell -- fcheck` (or direct `nix-fast-build ...`)
   - `nix flake check`
6. Document quick usage in a short lookup doc under `docs/reference/` and link it from `docs/README.md`.