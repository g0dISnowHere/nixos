# pnpm Globals

This directory is the source of truth for repo-managed npm CLI tools.
`scripts/sync-pnpm-globals.sh` copies these files into
`${XDG_DATA_HOME:-$HOME/.local/share}/mine/pnpm-globals`, runs
`pnpm install --frozen-lockfile`, and writes managed wrappers in
`$HOME/.local/bin`.

`package.json` keeps the direct dependencies. `pnpm-lock.yaml` keeps resolved
versions. `.npmrc` records the intended release-age policy, while
`pnpm-workspace.yaml` is the pnpm 11 settings file that actually enforces that
policy and approved dependency build scripts.

`headroom-ai` is kept as a locked dependency, but version `0.22.4` does not
publish a `headroom` npm binary. The sync script only manages wrappers for
commands present in `node_modules/.bin`.
