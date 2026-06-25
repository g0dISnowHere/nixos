# nix-fast-build

Fast multi-target build check for this repo.

## Why use it

Use `fcheck` before `nix flake check` or deploy commands to quickly catch build breakage across core targets.

Best for shared-module changes that can affect multiple machines/users.

## Run from dev shell

```bash
devenv shell
fcheck
```

## What `fcheck` builds

- `.#nixosConfigurations.centauri.config.system.build.toplevel`
- `.#nixosConfigurations.mirach.config.system.build.toplevel`
- `.#nixosConfigurations.albaldah.config.system.build.toplevel`
- `.#homeConfigurations."djoolz@workstation".activationPackage`

## Direct command

```bash
nix-fast-build \
  .#nixosConfigurations.centauri.config.system.build.toplevel \
  .#nixosConfigurations.mirach.config.system.build.toplevel \
  .#nixosConfigurations.albaldah.config.system.build.toplevel \
  .#homeConfigurations."djoolz@workstation".activationPackage
```

## Typical workflow

```bash
nix fmt
fcheck
nix flake check
```

## Where to use in your pipeline

- **Pre-commit:** keep current fast eval/lint checks (`scripts/validate-fast.sh`).
- **Pre-push / manual gate:** run `fcheck` to catch real build breakage across core targets.
- **CI/build jobs:** use `nix-fast-build` for multi-target parallel builds.

## Notes

- `nix-fast-build` is most useful for multiple targets; single-target speedups are usually small.
- It complements (does not replace) `nix eval` checks and full validation (`nix flake check`, `sh validate.sh`).

## Remote build example (albaldah)

Build only albaldah on a remote builder over SSH:

```bash
nix-fast-build \
  --remote ssh://<user>@albaldah \
  .#nixosConfigurations.albaldah.config.system.build.toplevel
```

If SSH config defines host/user, this shorter form works:

```bash
nix-fast-build --remote albaldah .#nixosConfigurations.albaldah.config.system.build.toplevel
```

## Troubleshooting

- If `fcheck` is missing, re-enter shell: `devenv shell`.
- If lock is stale after input changes: `nix flake update nix-fast-build`.
- If one target fails, build it directly to focus debugging:

```bash
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```
