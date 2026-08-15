# Rust Packages

This directory is the source of truth for repo-managed Rust CLI packages.
`scripts/sync-rustpackages.sh` installs the pinned crates from `packages.txt`
into `${XDG_DATA_HOME:-$HOME/.local/share}/mine/rustpackages`. Home Manager
adds its `bin` directory to `PATH`.

Each line in `packages.txt` contains one crates.io package name and version.
Normal sync installs those pinned versions. `scripts/sync-rustpackages.sh --update`
resolves latest versions, installs them, and rewrites `packages.txt`.
Run `scripts/sync.sh` to sync flake inputs and all managed package projects
together.
