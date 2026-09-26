#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/sync.sh [--dry-run] [--update]

Sync flake inputs and repo-managed pnpm, uv, AI skills, and Rust packages.

Options:
  --dry-run  Show planned commands without changing state.
  --update   Refresh pnpm and uv lockfiles and Rust crate pins.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
lock_root="${XDG_RUNTIME_DIR:-/tmp}"
lock_file="${lock_root}/mine-sync-$(id -u).lock"
dry_run=0
update_packages=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    --update)
      update_packages=1
      shift
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

run_command() {
  if [[ "$dry_run" -eq 1 ]]; then
    printf 'would run:'
    printf ' %q' "$@"
    printf '\n'
    return
  fi
  "$@"
}

sync_package_project() {
  local script="$1"
  shift

  if [[ ! -r "${script_dir}/${script}" ]]; then
    printf 'sync script missing: %s\n' "${script_dir}/${script}" >&2
    return 1
  fi
  run_command bash "${script_dir}/${script}" "$@"
}

sync_step() {
  local name="$1"
  shift

  printf 'Syncing %s\n' "$name"
  if "$@"; then
    return
  fi
  printf 'Failed to sync %s\n' "$name" >&2
  return 1
}

sync_repository() {
  local failed=0
  local -a package_args=()

  cd "$repo_root"
  if [[ "$update_packages" -eq 1 ]]; then
    package_args=(--update)
  fi

  if ! sync_step 'flake inputs' run_command nix flake update; then
    failed=1
  fi
  if ! sync_step 'pnpm globals' sync_package_project sync-pnpm-globals.sh "${package_args[@]}"; then
    failed=1
  fi
  if ! sync_step 'uv tools' sync_package_project sync-uv-tools.sh "${package_args[@]}"; then
    failed=1
  fi
  if ! sync_step 'AI skills' sync_package_project sync-ai-skills.sh; then
    failed=1
  fi
  if ! sync_step 'Rust packages' sync_package_project sync-rustpackages.sh "${package_args[@]}"; then
    failed=1
  fi

  if [[ "$failed" -eq 1 ]]; then
    printf 'Repository sync completed with failures\n' >&2
    return 1
  fi
}

mkdir -p "$(dirname "$lock_file")"
exec 9>"$lock_file"
if ! flock -n 9; then
  printf 'another repository sync is already running\n' >&2
  exit 1
fi

sync_repository
