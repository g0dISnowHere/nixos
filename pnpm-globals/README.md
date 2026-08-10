# pnpm Globals

This directory is the source of truth for repo-managed npm CLI tools.
`scripts/sync-pnpm-globals.sh` copies these files into
`${XDG_DATA_HOME:-$HOME/.local/share}/mine/pnpm-globals` and runs
`pnpm install --frozen-lockfile`. Home Manager adds
`$HOME/.local/share/mine/pnpm-globals/node_modules/.bin` to `PATH`. It does
not take over or clean pnpm's standard global store paths.

`package.json` keeps direct dependencies. `pnpm-lock.yaml` keeps resolved
versions. `.npmrc` records intended release-age policy, while
`pnpm-workspace.yaml` is pnpm 11 settings file that actually enforces policy
and approved dependency build scripts.

`headroom-ai` is kept as a locked dependency, but version `0.22.4` does not
publish a `headroom` npm binary.
