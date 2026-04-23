# Development Templates

This repo exposes reusable project templates from the root flake under
`templates`.

Template bodies live under `dev-templates/<name>/`. The root export lives in
`parts/templates.nix`.

## Use

Create a new project from a template:

```bash
nix flake new --template path:/home/djoolz/Documents/01_config/mine#rust ./my-rust-project
```

Initialize the current directory:

```bash
nix flake init --template path:/home/djoolz/Documents/01_config/mine#python
```

From the repo root, the shorter local form works:

```bash
nix flake new --template .#empty /tmp/template-test
```

## List Templates

```bash
nix flake show path:/home/djoolz/Documents/01_config/mine
```

Look under the `templates` output.

## Maintenance

- Add template files under `dev-templates/<name>/`.
- Add the matching explicit export in `parts/templates.nix`.
- Keep template names stable once used by projects.
- Prefer explicit exports over recursive directory discovery.
- Keep templates self-contained so generated projects do not depend on this
  repo after creation.

## Validation

Check that a template export evaluates:

```bash
nix eval .#templates.rust.description
```

Smoke-test template creation:

```bash
nix flake new --template .#empty /tmp/dev-template-test
```
