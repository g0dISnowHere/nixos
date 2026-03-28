# Home Dotfiles Backup And Zsh History Findings

Date: 2026-03-28

## Summary

The current setup does not provide a general, versioned backup system for all
user dotfiles. Home Manager handles some collision backups during activation,
but most important desktop config on `centauri` is currently deployed as
Home Manager-managed symlinks rather than app-owned writable files.

If the goal is "apps own their config, Home Manager only tracks and backs it
up", the live wiring for several desktop paths needs to change.

## Current Backup Behavior

- `flake/lib.nix` sets a custom `home-manager.backupCommand`.
- It writes backups under `~/.local/state/home-manager-backups`.
- The directory is created lazily only when Home Manager encounters a conflict
  it decides to back up.
- It is not a general snapshot system for dotfiles.
- It does not cover custom activation logic that directly manipulates files.

Observed state on `djoolz@centauri`:

- `~/.local/state/home-manager-backups` did not exist.
- No backup content for `~/.ssh` was present there.

## How Niri Is Wired Today

The main desktop config is wired through
`modules/home/desktop/niri.nix`.

These paths are Home Manager-managed symlinks to repo-backed content:

- `~/.config/niri/config.kdl`
- `~/.config/niri/swaylock-noctalia.sh`
- `~/.config/nirinit`
- `~/.config/waybar`
- `~/.config/mako`
- `~/.config/fuzzel`

This means:

- the repo is the source of truth
- Home Manager deploys the live paths
- the apps are not the primary writers for those config locations

## Noctalia Is Special-Cased

`~/.config/noctalia` is handled differently.

- The directory itself is kept writable.
- A custom activation script then symlinks individual files and subdirectories
  into the repo.
- That activation path uses direct `rm -f`, `mv`, and `ln -sfn` operations.
- This bypasses the general Home Manager collision-backup flow.

This is a higher-risk pattern than normal Home Manager link management.

## SSH Findings

`modules/home/programs/ssh.nix` enables SSH client config through Home Manager.

- `~/.ssh/config` is Home Manager-managed.
- The rest of `~/.ssh` is not managed by Home Manager.
- Private keys and host-specific key files are still live files in `~/.ssh`.

Safe inclusion guidance:

- include `~/.ssh/config`
- exclude `~/.ssh/id_*`
- exclude host private keys such as `~/.ssh/mirach`, `~/.ssh/strato`, etc.
- exclude `known_hosts` by default unless host-history backup is explicitly
  wanted

## Broader Dotfile Inventory Findings

Beyond repo-tracked desktop config, the home directory currently includes
several likely config candidates:

- `~/.gitconfig`
- `~/.config/git/config`
- `~/.config/git/ignore`
- `~/.zshrc`
- `~/.zshenv`
- `~/.config/home-manager/flake.nix`
- `~/.config/home-manager/home.nix`
- `~/.config/home-manager/flake.lock`
- desktop config under `~/.config/niri`, `~/.config/nirinit`,
  `~/.config/waybar`, `~/.config/mako`, `~/.config/fuzzel`,
  `~/.config/noctalia`
- Nautilus scripts and Python extensions under `~/.local/share`

The home directory also contains many paths that should be excluded from any
generic config backup:

- `~/.gnupg`
- `~/.local/share/keyrings`
- most of `~/.ssh`
- secret files such as `.env`
- browser/Electron profile directories with cookies, tokens, locks, and
  transient state
- shell history, lockfiles, and caches

## Zsh Findings

`~/.zshrc` is currently Home Manager-generated from
`modules/home/programs/shell.nix`.

Current behavior includes:

- `HISTFILE=~/.zsh_history`
- `SHARE_HISTORY` enabled
- `HIST_IGNORE_DUPS` enabled

Effect of `SHARE_HISTORY`:

- shell sessions share history immediately
- commands from different terminals are interleaved
- history is global rather than project-isolated

## Preferred Direction

If the intended model is:

"Nothing hard-set through Home Manager, just tracked safely, like app-owned
Niri config, with credentials excluded"

then the future design should be:

1. Apps write directly to their own live config paths.
2. Home Manager installs only the backup/retention machinery.
3. A user service snapshots selected live config paths into a versioned backup
   location under `~/.local/state/`.
4. Credentials and secret-bearing paths are excluded by default.
5. Restore should work at file or app-directory granularity.

## Zsh Follow-Up Direction

For shell history, the desired "opposite of share history" behavior is not a
separate `zshrc` per environment. The correct approach is a dynamic
project-local `HISTFILE`.

Recommended model:

- keep one shared `~/.zshrc`
- disable `SHARE_HISTORY`
- set `HISTFILE` dynamically from the current project root
- use one history file per project
- use a global fallback history outside projects

This keeps shell behavior consistent while preventing cross-project history
mixing.
