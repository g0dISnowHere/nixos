# uv Tools

This directory is the source of truth for repo-managed Python CLI tools that
are installed with uv.

`scripts/sync-uv-tools.sh` copies `pyproject.toml` and `uv.lock` into
`${XDG_DATA_HOME:-$HOME/.local/share}/mine/uv-tools`, runs
`uv sync --frozen`, and writes managed wrappers in `$HOME/.local/bin`.

The direct tool dependencies currently come from the existing uv tool receipts:

- `basic-memory`, exposing `basic-memory` and `bm`
- `graphifyy`, exposing `graphify`
- `headroom-ai`, exposing `headroom`
- `specify-cli` from `github/spec-kit`, exposing `specify`

Normal sync uses the committed lockfile and does not update versions.
`scripts/sync-uv-tools.sh --update` refreshes `uv.lock` with a three-day
`--exclude-newer` cutoff before syncing.
