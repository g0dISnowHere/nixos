# Fast Development Workflow

## Instant direnv

Home Manager enables `direnv-instant` for Bash and Zsh. It starts `direnv` in a
background daemon, returns the prompt immediately, then refreshes the shell
when the environment is ready. It reuses the last environment while it
revalidates the current directory.

Use it with the existing `nix-direnv` integration:

```bash
direnv allow
devenv shell
```

Do not add `eval "$(direnv hook zsh)"` or another standard direnv hook to shell
configuration. `direnv-instant` replaces that hook. When evaluation takes more
than four seconds, it opens a multiplexer pane with direnv output; use Ctrl-C
there to stop a stuck evaluation.

## Repository-local codebase memory

`codebase-memory-mcp` is provided by this repository's unstable `devenv`
channel and registered only through the root [`.mcp.json`](../../.mcp.json).
Enter the development shell before using the CLI directly:

```bash
devenv shell
codebase-memory-mcp
```

The MCP server confines indexing and its cache to this repository via
`CBM_ALLOWED_ROOT=.` and `CBM_CACHE_DIR=.codebase-memory`. The cache is ignored
by Git.

## Test a local flake input

Use `fast-flake-update` when testing a local Git checkout of a flake input. It
writes the same `flake.lock` change as a remote update without downloading the
remote source archive again.

```bash
nix run .#fast-flake-update -- nixpkgs ~/src/nixpkgs
```

Use the exact root input name. For a local checkout of the unstable channel:

```bash
nix run .#fast-flake-update -- nixpkgs-unstable ~/src/nixpkgs
```

Pin a specific local commit when needed:

```bash
nix run .#fast-flake-update -- --rev <commit> nixpkgs ~/src/nixpkgs
```

Use `nix flake update` and `scripts/update-system.sh` for normal remote input
updates. `fast-flake-update` only supports deliberate local-checkout testing.

## Pull with local changes

`git pull` cannot proceed when local edits would be overwritten or when the
index already contains unmerged paths. A recent incident combined both cases:

1. Local edits and untracked findings existed while `flake.lock` and
   `scripts/README.md` still had unresolved stash conflicts.
2. The first `git pull` stopped because unmerged files remained.
3. After resolving those files, `git pull` still stopped because remote commits
   touched files with local edits.
4. Stashing tracked and untracked work, pulling, then applying the stash
   restored local changes but produced two new documentation conflicts.
5. The conflicts were resolved by keeping the current flake inputs in
   `flake.lock`, combining non-overlapping script documentation, and preserving
   the local proposal status.

Safer workflow:

```bash
git status --short --branch
git diff --check
git stash push --include-untracked -m "pre-pull local work"
git pull
git stash pop
```

For lockfile conflicts, always keep the most recent lockfile. Identify the
newer side from commit chronology or lock metadata, then take that file
whole; never manually merge lockfile JSON or choose a side because it is
shorter. Validate its input topology against `flake.nix` afterward.

After applying the stash:

```bash
git diff --name-only --diff-filter=U
git diff --check
python -m json.tool flake.lock >/dev/null
bash -n scripts/*.sh
git status --short --branch
```

Do not drop the backup stash until restored files and validation pass. Keep
local changes uncommitted unless the user explicitly asks for a commit.

## Validate input topology

Run the targeted input linter:

```bash
nix run .#flakelintRepo
```

Run the fast validation pipeline:

```bash
bash scripts/validate-fast.sh
```

The pipeline evaluates each configured host and Home Manager profile, checks
secrets policy, runs shell/Nix/Markdown linters, and builds the flake-linter
check. The pre-commit hook instead limits itself to formatting staged Nix files
and auto-fixing staged Markdown, so use this command before pushing changes.

`flake-linter` reports the root stable and unstable Nixpkgs inputs as separate
versions. This repository keeps both: NixOS hosts use `nixos-26.05`, while
Noctalia follows `nixpkgs-unstable`.

For parallel multi-target builds, use [`nix-fast-build.md`](nix-fast-build.md).
