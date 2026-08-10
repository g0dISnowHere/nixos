# uv Tools

This directory is the source of truth for repo-managed Python CLI tools that
are installed with uv.

`scripts/sync-uv-tools.sh` copies `pyproject.toml` and `uv.lock` into
`${XDG_DATA_HOME:-$HOME/.local/share}/mine/uv-tools` and runs `uv sync
--frozen`. Home Manager adds
`$HOME/.local/share/mine/uv-tools/.venv/bin` to `PATH`. It does not take over
or clean uv's standard tool store paths.

Direct tool dependencies currently expose:

- `basic-memory`, exposing `basic-memory` and `bm`
- `headroom-ai`, exposing `headroom`

Normal sync uses the committed lockfile and does not update versions.
`scripts/sync-uv-tools.sh --update` refreshes `uv.lock` with a three-day
`--exclude-newer` cutoff before syncing.
