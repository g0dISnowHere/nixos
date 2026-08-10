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

export DISABLE_TELEMETRY=1
for source in "${managed_sources[@]}"; do
  printf 'Installing managed global skills from %s\n' "$source"
  "$skills_cmd" add "$source" -g --all
done
