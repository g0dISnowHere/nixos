#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/update-system.sh [options]

Updates flake inputs, synchronizes repo-managed pnpm, uv, and Rust packages,
and rebuilds this NixOS host from an existing checkout.

Options:
  --host HOST       NixOS host name to switch. Default: hostname -s
  --repo PATH       Existing Git checkout. Default: ~/nixos-deploy
  --repo-user USER  User account used for Git and package operations.
                    Default: invoking user, or SUDO_USER when invoked via sudo
  --remote REMOTE   Git remote to use. Default: origin
  --branch BRANCH   Git branch allowed for automation. Default: main
EOF
}

host="$(hostname -s)"
repo_root=""
repo_user="${SUDO_USER:-$USER}"
remote="origin"
branch="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      host="${2:?missing host name}"
      shift 2
      ;;
    --repo)
      repo_root="${2:?missing repo path}"
      shift 2
      ;;
    --repo-user)
      repo_user="${2:?missing repo user}"
      shift 2
      ;;
    --remote)
      remote="${2:?missing remote name}"
      shift 2
      ;;
    --branch)
      branch="${2:?missing branch name}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$repo_root" ]]; then
  if [[ "$(id -u)" -eq 0 ]]; then
    repo_home="$(getent passwd "$repo_user" | cut -d: -f6)"
  else
    repo_home="$HOME"
  fi
  repo_root="${repo_home}/nixos-deploy"
fi

run_as_repo_user() {
  if [[ "$(id -un)" == "$repo_user" ]]; then
    "$@"
  else
    sudo -H -u "$repo_user" "$@"
  fi
}

git_user() {
  run_as_repo_user git -C "$repo_root" "$@"
}

require_branch_safe_checkout() {
  local branch_name

  if [[ ! -d "$repo_root/.git" ]]; then
    printf 'Refusing update: %s is not a Git checkout\n' "$repo_root" >&2
    exit 1
  fi

  branch_name="$(git_user symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  if [[ "$branch_name" != "$branch" ]]; then
    printf 'Refusing update: checkout is on "%s", expected "%s"\n' \
      "${branch_name:-detached HEAD}" "$branch" >&2
    exit 1
  fi

  if ! git_user diff --quiet --ignore-submodules HEAD -- ||
    ! git_user diff --cached --quiet --ignore-submodules --; then
    printf 'Refusing update: tracked changes are present on %s\n' "$branch" >&2
    exit 1
  fi
}

sync_repository() {
  local sync_script="${repo_root}/scripts/sync.sh"

  if [[ ! -r "$sync_script" ]]; then
    printf 'repository sync script missing: %s\n' "$sync_script" >&2
    exit 1
  fi

  printf 'Syncing flake and managed packages for %s\n' "$repo_user"
  run_as_repo_user bash "$sync_script"
}

switch_system() {
  local rebuild_cmd=(nixos-rebuild switch --flake ".#${host}")

  printf 'Switching host %s\n' "$host"
  if [[ "$(id -u)" -eq 0 ]]; then
    "${rebuild_cmd[@]}"
  else
    sudo "${rebuild_cmd[@]}"
  fi
}

require_branch_safe_checkout
cd "$repo_root"

printf 'Pulling %s/%s\n' "$remote" "$branch"
git_user pull --ff-only "$remote" "$branch"

sync_repository

if ! git_user diff --quiet -- flake.lock || ! git_user diff --cached --quiet -- flake.lock; then
  git_user add flake.lock
  git_user commit -m "updates" -- flake.lock
  git_user push "$remote" "$branch"
  printf 'Git: pushed updated flake.lock\n'
else
  printf 'Git: flake.lock already current\n'
fi

switch_system
