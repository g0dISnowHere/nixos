#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/sync-uv-tools.sh [--dry-run] [--update]

Sync repo-managed Python CLI tools from uv-tools/ into the current user's
XDG data directory, then expose managed wrappers in $HOME/.local/bin.

Options:
  --dry-run  Show planned paths and wrapper names without changing state.
  --update   Refresh uv-tools/uv.lock before syncing.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
source_dir="${repo_root}/uv-tools"
xdg_data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
runtime_dir="${xdg_data_home}/mine/uv-tools"
runtime_bin="${runtime_dir}/.venv/bin"
local_bin="${HOME}/.local/bin"
legacy_uv_tools_dir="${xdg_data_home}/uv/tools"
lock_root="${XDG_RUNTIME_DIR:-/tmp}"
lock_file="${lock_root}/mine-uv-tools-$(id -u).lock"
managed_marker="# managed-by: mine/scripts/sync-uv-tools.sh"
wrapper_commands=(basic-memory bm graphify headroom specify)
legacy_tool_dirs=(basic-memory graphifyy headroom-ai specify-cli)
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

uv_cmd="$(command -v uv || true)"
if [[ -z "$uv_cmd" && -x /run/current-system/sw/bin/uv ]]; then
  uv_cmd=/run/current-system/sw/bin/uv
fi
if [[ -z "$uv_cmd" ]]; then
  printf 'uv is not available in PATH\n' >&2
  exit 1
fi

export UV_NO_MANAGED_PYTHON=1
export UV_PYTHON_DOWNLOADS=never
export UV_PYTHON="${UV_PYTHON:-python3.13}"

required_files=(pyproject.toml)
if [[ "$update_lock" -eq 0 ]]; then
  required_files+=(uv.lock)
fi

for required in "${required_files[@]}"; do
  if [[ ! -r "${source_dir}/${required}" ]]; then
    printf 'uv tools source file missing or unreadable: %s\n' "${source_dir}/${required}" >&2
    exit 1
  fi
done

cooldown_cutoff() {
  date -u -d '3 days ago' '+%Y-%m-%dT%H:%M:%SZ'
}

is_managed_wrapper() {
  local path="$1"
  [[ -f "$path" ]] && grep -Fqx "$managed_marker" "$path"
}

is_legacy_uv_tool_wrapper() {
  local path="$1"
  local target

  [[ -L "$path" ]] || return 1
  target="$(readlink -f "$path" 2>/dev/null || true)"
  if [[ -z "$target" ]]; then
    target="$(readlink "$path" 2>/dev/null || true)"
  fi
  [[ "$target" == "${legacy_uv_tools_dir}"/* ]]
}

assert_wrapper_target_available() {
  local command="$1"
  local target="${runtime_bin}/${command}"

  if [[ ! -x "$target" ]]; then
    printf 'expected runtime command missing or not executable: %s\n' "$target" >&2
    exit 1
  fi
}

write_wrapper() {
  local command="$1"
  local wrapper="${local_bin}/${command}"
  local target="${runtime_bin}/${command}"

  if [[ -e "$wrapper" ]] && ! is_managed_wrapper "$wrapper" && ! is_legacy_uv_tool_wrapper "$wrapper"; then
    printf 'refusing to overwrite unmanaged command: %s\n' "$wrapper" >&2
    exit 1
  fi
  if is_legacy_uv_tool_wrapper "$wrapper"; then
    rm -f "$wrapper"
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
    printf 'uv tools source: %s\n' "$source_dir"
    printf 'uv tools runtime: %s\n' "$runtime_dir"
    printf 'managed wrapper dir: %s\n' "$local_bin"
    printf 'managed commands:\n'
    printf ' - %s\n' "${wrapper_commands[@]}"
    if [[ "$update_lock" -eq 1 ]]; then
      printf 'would refresh source lockfile with exclude-newer cutoff: %s\n' "$(cooldown_cutoff)"
    fi
    return
  fi

  if [[ "$update_lock" -eq 1 ]]; then
    printf 'Refreshing uv-tools lockfile with exclude-newer cutoff %s\n' "$(cooldown_cutoff)"
    "$uv_cmd" lock --project "$source_dir" --upgrade --exclude-newer "$(cooldown_cutoff)"
  fi

  mkdir -p "$runtime_dir" "$local_bin"
  install -m 0644 "${source_dir}/pyproject.toml" "${runtime_dir}/pyproject.toml"
  install -m 0644 "${source_dir}/uv.lock" "${runtime_dir}/uv.lock"

  printf 'Installing uv tools runtime in %s\n' "$runtime_dir"
  "$uv_cmd" sync --project "$runtime_dir" --frozen --no-dev --no-install-project

  for command in "${wrapper_commands[@]}"; do
    assert_wrapper_target_available "$command"
  done

  for command in "${wrapper_commands[@]}"; do
    write_wrapper "$command"
  done
  remove_obsolete_wrappers

  for tool_dir in "${legacy_tool_dirs[@]}"; do
    rm -rf "${legacy_uv_tools_dir:?}/${tool_dir}"
  done

  printf 'uv tools: sync complete\n'
}

mkdir -p "$(dirname "$lock_file")"
exec 9>"$lock_file"
if ! flock -n 9; then
  printf 'another uv tools sync is already running\n' >&2
  exit 1
fi

sync_locked_project
