# Devenv Migration Plan

Status: proposal. Scope: repo-local dev shell and reusable `dev-templates/`.

## Goals

- Move dev environments to `devenv.nix`.
- Keep NixOS, Home Manager, checks, formatter, and template exports in the root flake.
- Install `devenv` on all NixOS systems, including servers.
- Do not preserve backwards compatibility for old dev shells or old template internals.

## Plan 1: Repository Dev Environment

Current state:

- `parts/devshells.nix` defines `devShells.default` with `pkgs.mkShell`.
- `outputs.nix` imports `./parts/devshells.nix`.
- Shell provides repo tools, Nix linker env vars, and aliases.

Target state:

- Root `devenv.nix` owns the interactive repo dev environment.
- Root flake remains for NixOS/Home Manager outputs, checks, formatter, templates.
- `devenv shell` is the canonical entrypoint.
- `nix develop` compatibility is not required.
- `devenv` is installed system-wide through NixOS common modules, not Home Manager, because not every host uses Home Manager.

Steps:

1. Add a shared NixOS module to install `devenv` on every host using `mkNixosSystem`.
   - suggested path: `modules/nixos/system/devenv.nix`
   - contents: `environment.systemPackages = [ pkgs.devenv ];`
   - import from the common module list in `flake/lib.nix`
   - export it as `nixosModules.devenv` for explicit reuse
2. Add root `devenv.nix` mirroring `parts/devshells.nix`.
   - packages: `python3`, `nixpkgs-fmt`, `statix`, `deadnix`, `flake-linter`, `markdownlint-cli`, `shellcheck`, `nix-fast-build`
   - env: `NIX_LD_LIBRARY_PATH`, `NIX_LD`, `GREET`, `ZDOTDIR`
   - `enterShell`: existing aliases and greeting
3. Use standalone devenv.
   - `devenv shell` is the supported entrypoint
   - do not preserve `nix develop`
4. Remove old mkShell wiring.
   - delete or stop importing `parts/devshells.nix`
   - keep formatter/checks/templates unchanged
5. Validate.
   - `devenv shell -- echo ok`
   - `devenv shell -- statix check .`
   - targeted `nix eval` for all machine outputs, including servers
6. Update docs.
   - `AGENTS.md` development commands
   - README/reference docs if they mention `nix develop` as the only entrypoint

Risks:

- `flake-linter` and `nix-fast-build` currently come from flake inputs; standalone `devenv.nix` needs a clean way to access them or use packages from `pkgs` when available.
- Hosts not using `mkNixosSystem` would not receive the shared `devenv` package automatically.

## Plan 2: `dev-templates/` Migration

Current state:

- Each template contains `flake.nix` and `.envrc` with `use flake`.
- Root flake exports templates explicitly from `parts/templates.nix`.
- Docs instruct users to create projects with `nix flake new/init`, then enter with `nix develop` or `direnv allow`.

Target state:

- `nix`, `python`, `node`, and `platformio` templates use real `devenv.nix` environments.
- Root flake still exports templates; generated projects do not contain `flake.nix` unless a specific template needs one.
- Existing template names are reused for devenv versions.
- All other templates are replaced with a stub `devenv.nix` that prints a migration alert and exits before providing a usable shell.

Steps:

1. Convert `dev-templates/nix/` in place.
   - remove `flake.nix`
   - `.envrc`: `use devenv`
   - add `devenv.nix`
   - mirror the current repo dev shell package/env/alias setup
2. Convert `dev-templates/python/` in place.
   - remove `flake.nix`
   - port current behavior: Python version, uv-managed `.venv`, pyright/mypy/ruff/pre-commit/test tools
   - keep manual `.venv` deletion on Python version mismatch
3. Convert `dev-templates/node/` in place.
   - remove `flake.nix`
   - keep current package intent: `nodejs`, `node2nix`, `pnpm`, `yarn`
4. Convert `dev-templates/platformio/` in place.
   - remove `flake.nix`
   - keep current package set: `clang-tools`, `cmake`, `codespell`, `conan`, `cppcheck`, `doxygen`, `gtest`, `lcov`, `platformio`, `vcpkg`, `vcpkg-tool`
   - keep `gdb` except on `aarch64-darwin`
   - keep `PLATFORMIO_CORE_DIR=$PWD/.platformio`
5. Replace all other templates in place with migration-alert stubs.
   - remove `flake.nix`
   - `.envrc`: `use devenv`
   - `devenv.nix` prints a clear "template not migrated yet" message and exits non-zero
   - use one script or shared generation step for stubs so wording and behavior stay consistent
6. Keep `parts/templates.nix` names unchanged unless files move.
7. Add `dev-templates/README_FOR_AI.md` before broad template edits.
   - record that templates are devenv-based
   - forbid reintroducing per-template flake dev shells unless explicitly requested
   - document that most templates are intentional migration-alert stubs
8. Update docs.
   - `docs/dev-templates.md`: templates are devenv-based
   - `dev-templates/README.md`: use `devenv shell` and `direnv allow`
9. Validate template exports and generated projects.
   - `nix eval .#templates.nix.description`
   - `nix flake new --template .#nix /tmp/nix-devenv-test`
   - `cd /tmp/nix-devenv-test && devenv shell -- echo ok`
   - repeat for `python`, `node`, and `platformio`
   - smoke-test one stub template and confirm it exits with the migration alert
   - grep for stale flake-shell language and decide which remaining mentions are intentional:
     `rg -n "use flake|nix develop|devShells|mkShell|flake-based" dev-templates docs AGENTS.md README.md`

Risks:

- `nix flake new` remains the transport for templates while generated projects are usually not flakes; docs must make this distinction clear.
- Users outside managed NixOS hosts need `devenv` installed before generated environments work.
- Current `.envrc` uses `use flake`; templates need `use devenv` and compatible direnv setup.
- Stub templates intentionally fail until migrated.
- Aliases in `enterShell` are interactive-shell conveniences; if they become important for non-interactive use, move them to scripts later.
- Template lock policy should be explicit: commit root `devenv.lock` if generated, but avoid shipping template lockfiles unless a template needs a fixed pin.

## Suggested First Implementation Batch

1. Add `modules/nixos/system/devenv.nix`, import it from `flake/lib.nix` common modules, and export it as `nixosModules.devenv`.
2. Add root `devenv.nix`.
3. Remove root mkShell wiring from `outputs.nix`.
4. Add `dev-templates/README_FOR_AI.md`.
5. Convert `dev-templates/nix/`, `python/`, `node/`, and `platformio/` in place.
6. Replace all other templates with migration-alert stubs via one consistent generation step.
7. Update docs.
8. Validate with `devenv shell`, all relevant `nix eval` machine checks, `nix eval .#templates.*.description`, and the stale-language grep.
