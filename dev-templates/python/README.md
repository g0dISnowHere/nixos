# Python template

This template provides:

- a Nix development shell with Python 3.13
- `uv` for virtualenv and package management
- a `src/` package layout
- `ruff`, `basedpyright`, `mypy`, `pytest`, `coverage`, and `pre-commit`
- a `justfile` for common development tasks

## Workflow

Enter the shell:

```sh
direnv allow
```

or:

```sh
nix develop
```

The shell will create and activate `.venv` automatically with `uv`.
If `uv.lock` exists, the shell will also run `uv sync --frozen` automatically.
On first entry into a generated project, the shell will initialize Git, install the
`pre-commit` hook, and create an initial commit when Git user identity is configured.

Install project dependencies:

```sh
uv sync
```

Install Git hooks:

```sh
pre-commit install
```

Run common tasks:

```sh
just sync
just hooks
just fmt
just lint
just typecheck
just test
just test-cov
just check
```

Run checks manually:

```sh
ruff check --fix .
ruff format .
mypy src tests
pytest -q
coverage run -m pytest
coverage report
pre-commit run --all-files
```
