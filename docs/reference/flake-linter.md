# Flake Linter

Quick commands for `flake-linter` in this repo.

## Run It

Run only the linter check:

```bash
nix build .#checks.x86_64-linux.flake-linter
```

Run the full checks suite (includes flake-linter):

```bash
nix flake check -L
```

Run from dev shell:

```bash
devenv shell
flake-linter .
```

Or via package app wrapper:

```bash
nix run .#flakelintRepo
```

`scripts/validate-fast.sh` builds this check. It is a manual pre-push
validation gate; the pre-commit hook does not run it.

## Typical Output And What To Do

### "has multiple versions"

This means different inputs pin different upstream revisions.

Check paths:

```bash
nix flake metadata --json | jq '.locks.nodes'
```

Inspect why an input is present:

```bash
nix why-depends .#checks.x86_64-linux.flake-linter <store-path>
```

Act on it only when useful:

- Keep as-is if divergence is intentional or harmless.
- Align with `follows` where feasible in `flake.nix`.
- Update locks and re-check:

```bash
nix flake update
nix flake check -L
```

## Fast Loop

`flake-fmt` caches this flake's `formatter` output. Format locally:

```bash
nix run --no-write-lock-file .#flake-fmt --
```

Check formatting without changing files:

```bash
nix run --no-write-lock-file .#flake-fmt -- -- --ci
```

Then run the linter and full checks:

```bash
nix build .#checks.x86_64-linux.flake-linter
nix flake check -L
```
