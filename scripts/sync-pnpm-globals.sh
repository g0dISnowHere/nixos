#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/sync-pnpm-globals.sh [--dry-run] [--update]

Sync repo-managed npm CLI tools from pnpm-globals/ into the current user's
XDG data directory, then expose managed wrappers in $HOME/.local/bin.

Options:
  --dry-run  Show planned paths and wrapper names without changing state.
  --update   Refresh pnpm-globals/pnpm-lock.yaml before syncing.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
source_dir="${repo_root}/pnpm-globals"
xdg_data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
runtime_dir="${xdg_data_home}/mine/pnpm-globals"
local_bin="${HOME}/.local/bin"
lock_root="${XDG_RUNTIME_DIR:-/tmp}"
lock_file="${lock_root}/mine-pnpm-globals-$(id -u).lock"
managed_marker="# managed-by: mine/scripts/sync-pnpm-globals.sh"
wrapper_commands=(codex gemini copilot pi omp bun bunx)
dry_run=0
update_lock=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    --update)
      update_lock=1
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

pnpm_cmd="$(command -v pnpm || true)"
if [[ -z "$pnpm_cmd" && -x /run/current-system/sw/bin/pnpm ]]; then
  pnpm_cmd=/run/current-system/sw/bin/pnpm
fi
if [[ -z "$pnpm_cmd" ]]; then
  printf 'pnpm is not available in PATH\n' >&2
  exit 1
fi

export pnpm_config_minimum_release_age=4320
export pnpm_config_minimum_release_age_strict=true
export pnpm_config_minimum_release_age_ignore_missing_time=false

for required in package.json pnpm-lock.yaml .npmrc pnpm-workspace.yaml; do
  if [[ ! -r "${source_dir}/${required}" ]]; then
    printf 'pnpm globals source file missing or unreadable: %s\n' "${source_dir}/${required}" >&2
    exit 1
  fi
done

is_managed_wrapper() {
  local path="$1"
  [[ -f "$path" ]] && grep -Fqx "$managed_marker" "$path"
}

assert_wrapper_target_available() {
  local command="$1"
  local target="${runtime_dir}/node_modules/.bin/${command}"

  if [[ ! -x "$target" ]]; then
    printf 'expected runtime command missing or not executable: %s\n' "$target" >&2
    exit 1
  fi
}

write_wrapper() {
  local command="$1"
  local wrapper="${local_bin}/${command}"
  local target="${runtime_dir}/node_modules/.bin/${command}"

  if [[ -e "$wrapper" ]] && ! is_managed_wrapper "$wrapper"; then
    printf 'refusing to overwrite unmanaged command: %s\n' "$wrapper" >&2
    exit 1
  fi

  cat >"$wrapper" <<EOF
#!/usr/bin/env bash
${managed_marker}
exec "${target}" "\$@"
EOF
  chmod 0755 "$wrapper"
}

remove_obsolete_wrappers() {
  # Keep cleanup bounded to this script's command set. Do not scan arbitrary
  # executables in ~/.local/bin; some commands may block when read.
  :
}

sync_locked_project() {
  if [[ "$dry_run" -eq 1 ]]; then
    printf 'pnpm globals source: %s\n' "$source_dir"
    printf 'pnpm globals runtime: %s\n' "$runtime_dir"
    printf 'managed wrapper dir: %s\n' "$local_bin"
    printf 'managed commands:\n'
    printf ' - %s\n' "${wrapper_commands[@]}"
    if [[ "$update_lock" -eq 1 ]]; then
      printf 'would refresh source lockfile before syncing\n'
    fi
    return
  fi

  if [[ "$update_lock" -eq 1 ]]; then
    printf 'Refreshing pnpm-globals lockfile\n'
    "$pnpm_cmd" --dir "$source_dir" update --lockfile-only
  fi

  mkdir -p "$runtime_dir" "$local_bin"
  install -m 0644 "${source_dir}/package.json" "${runtime_dir}/package.json"
  install -m 0644 "${source_dir}/pnpm-lock.yaml" "${runtime_dir}/pnpm-lock.yaml"
  install -m 0644 "${source_dir}/.npmrc" "${runtime_dir}/.npmrc"
  install -m 0644 "${source_dir}/pnpm-workspace.yaml" "${runtime_dir}/pnpm-workspace.yaml"

  printf 'Installing pnpm globals runtime in %s\n' "$runtime_dir"
  "$pnpm_cmd" --dir "$runtime_dir" install --frozen-lockfile

  for command in "${wrapper_commands[@]}"; do
    assert_wrapper_target_available "$command"
  done

  for command in "${wrapper_commands[@]}"; do
    write_wrapper "$command"
  done
  remove_obsolete_wrappers

  rm -rf "${xdg_data_home}/pnpm/global" "${xdg_data_home}/pnpm/bin"
  printf 'pnpm globals: sync complete\n'
}

mkdir -p "$(dirname "$lock_file")"
exec 9>"$lock_file"
if ! flock -n 9; then
  printf 'another pnpm globals sync is already running\n' >&2
  exit 1
fi

sync_locked_project
