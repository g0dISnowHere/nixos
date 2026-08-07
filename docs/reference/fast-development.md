# Fast Development Workflow

## Instant direnv

Home Manager enables `direnv-instant` for Bash and Zsh. It starts `direnv` in a
background daemon, returns the prompt immediately, then refreshes the shell
when the environment is ready. It reuses the last environment while it
revalidates the current directory.

Use it with the existing `nix-direnv` integration:

```bash
direnv allow
devenv shell
```

Do not add `eval "$(direnv hook zsh)"` or another standard direnv hook to shell
configuration. `direnv-instant` replaces that hook. When evaluation takes more
than four seconds, it opens a multiplexer pane with direnv output; use Ctrl-C
there to stop a stuck evaluation.

## Test a local flake input

Use `fast-flake-update` when testing a local Git checkout of a flake input. It
writes the same `flake.lock` change as a remote update without downloading the
remote source archive again.

```bash
nix run .#fast-flake-update -- nixpkgs ~/src/nixpkgs
```

Use the exact root input name. For a local checkout of the unstable channel:

```bash
nix run .#fast-flake-update -- nixpkgs-unstable ~/src/nixpkgs
```

Pin a specific local commit when needed:

```bash
nix run .#fast-flake-update -- --rev <commit> nixpkgs ~/src/nixpkgs
```

Use `nix flake update` and `scripts/update-system.sh` for normal remote input
updates. `fast-flake-update` only supports deliberate local-checkout testing.

## Validate input topology

Run the targeted input linter:

```bash
nix run .#flakelintRepo
```

Run the fast validation pipeline:

```bash
bash scripts/validate-fast.sh
```

The pipeline evaluates each configured host and Home Manager profile, checks
secrets policy, runs shell/Nix/Markdown linters, and builds the flake-linter
check. The pre-commit hook runs this pipeline for staged Nix, Markdown, shell,
or `flake.lock` files.

`flake-linter` reports the root stable and unstable Nixpkgs inputs as separate
versions. This repository keeps both: NixOS hosts use `nixos-26.05`, while
Noctalia follows `nixpkgs-unstable`.

For parallel multi-target builds, use [`nix-fast-build.md`](nix-fast-build.md).
