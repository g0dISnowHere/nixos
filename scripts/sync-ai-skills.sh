#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/sync-ai-skills.sh [--list]

Installs or refreshes every listed AI skill pack globally for all supported
agents.

Options:
  --list     Print the managed skill-pack sources and exit.
  -h, --help Show this help text.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest_file="${script_dir}/global-skills.txt"

if [[ ! -r "$manifest_file" ]]; then
  printf 'Global skills manifest missing: %s\n' "$manifest_file" >&2
  exit 1
fi

managed_sources=()
while IFS= read -r source || [[ -n "$source" ]]; do
  [[ -z "$source" || "$source" == \#* ]] && continue
  managed_sources+=("$source")
done < "$manifest_file"

if [[ "${#managed_sources[@]}" -eq 0 ]]; then
  printf 'Global skills manifest is empty: %s\n' "$manifest_file" >&2
  exit 1
fi

case "${1:-}" in
  "") ;;
  --list)
    printf '%s\n' "${managed_sources[@]}"
    exit 0
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

skills_cmd="$(command -v skills || true)"
if [[ -z "$skills_cmd" && -x /run/current-system/sw/bin/skills ]]; then
  skills_cmd=/run/current-system/sw/bin/skills
fi
if [[ -z "$skills_cmd" ]]; then
  printf 'skills is not installed; rebuild the NixOS configuration first.\n' >&2
  exit 1
fi

lock_root="${XDG_RUNTIME_DIR:-/tmp}"
lock_file="${lock_root}/mine-ai-skills-$(id -u).lock"
mkdir -p "$(dirname "$lock_file")"
exec 9>"$lock_file"
if ! flock -n 9; then
  printf 'Another AI skills sync is already running.\n' >&2
  exit 1
fi

is_unsupported_global_agent_failure() {
  local results="$1"
  local error match
  local failure_count=0

  while [[ "$results" =~ \"error\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; do
    error="${BASH_REMATCH[1]}"
    match="${BASH_REMATCH[0]}"
    case "$error" in
      'Eve does not support global skill installation'|'PromptScript does not support global skill installation') ;;
      *) return 1 ;;
    esac
    results="${results#*"$match"}"
    ((failure_count += 1))
  done

  [[ "$failure_count" -gt 0 ]]
}

install_managed_source() {
  local source="$1"
  local results stderr_file

  stderr_file="$(mktemp)"
  if results="$("$skills_cmd" add "$source" -g --all --json 2>"$stderr_file")"; then
    cat "$stderr_file" >&2
    rm -f "$stderr_file"
    return
  fi

  if is_unsupported_global_agent_failure "$results"; then
    rm -f "$stderr_file"
    printf 'Skipped unsupported global skill agents for %s\n' "$source" >&2
    return
  fi

  cat "$stderr_file" >&2
  rm -f "$stderr_file"
  printf '%s\n' "$results" >&2
  return 1
}

export DISABLE_TELEMETRY=1
for source in "${managed_sources[@]}"; do
  printf 'Installing managed global skills from %s\n' "$source"
  install_managed_source "$source"
done
