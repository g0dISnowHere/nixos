# Development Templates

Repo exports reusable project templates from root flake under `templates`.

Template body lives in `dev-templates/<name>/`. Root export lives in
`parts/templates.nix`.

## Use

Create new project from template:

```bash
nix flake new --template path:/home/djoolz/Documents/01_config/mine#rust ./my-rust-project | tail -n 20
```

Init current directory:

```bash
nix flake init --template path:/home/djoolz/Documents/01_config/mine#python | tail -n 20
```

From repo root, shorter local form works:

```bash
nix flake new --template .#empty /tmp/template-test | tail -n 20
```

## List Templates

```bash
nix flake show path:/home/djoolz/Documents/01_config/mine | tail -n 20
```

Look under `templates` output.

## Maintenance

- add template files under `dev-templates/<name>/`
- add matching explicit export in `parts/templates.nix`
- keep template names stable once projects use them
- prefer explicit exports over recursive discovery
- keep templates self-contained so generated project not depend on this repo

## Validation

Check template export evaluates:

```bash
nix eval .#templates.rust.description | tail -n 20
```

Smoke-test template creation:

```bash
nix flake new --template .#empty /tmp/dev-template-test | tail -n 20
```
