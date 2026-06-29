#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/sync-pnpm-globals.sh [--manifest PATH] [--dry-run]
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="${script_dir}/pnpm-global-packages.txt"
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest)
      manifest="${2:?missing manifest path}"
      shift 2
      ;;
    --dry-run)
      dry_run=1
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

if [[ ! -r "$manifest" ]]; then
  printf 'pnpm globals manifest is not readable: %s\n' "$manifest" >&2
  exit 1
fi

pnpm_cmd="$(command -v pnpm || true)"
if [[ -z "$pnpm_cmd" && -x /run/current-system/sw/bin/pnpm ]]; then
  pnpm_cmd=/run/current-system/sw/bin/pnpm
fi
if [[ -z "$pnpm_cmd" ]]; then
  printf 'pnpm is not available in PATH\n' >&2
  exit 1
fi

python_cmd="$(command -v python3 || true)"
if [[ -z "$python_cmd" ]]; then
  printf 'python3 is required for manifest parsing\n' >&2
  exit 1
fi

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
export PATH="${PNPM_HOME}/bin:${PATH}"
export pnpm_config_global_dir="${pnpm_config_global_dir:-${PNPM_HOME}/global}"
export pnpm_config_global_bin_dir="${pnpm_config_global_bin_dir:-${PNPM_HOME}/bin}"
export pnpm_config_minimum_release_age="${pnpm_config_minimum_release_age:-20160}"
export pnpm_config_minimum_release_age_strict="${pnpm_config_minimum_release_age_strict:-true}"
export pnpm_config_minimum_release_age_ignore_missing_time="${pnpm_config_minimum_release_age_ignore_missing_time:-false}"

mkdir -p "${pnpm_config_global_bin_dir}" "${pnpm_config_global_dir}"

current_json="$($pnpm_cmd list -g --json --depth=-1 2>/dev/null || printf '[]\n')"
plan_json="$(CURRENT_JSON="$current_json" "$python_cmd" - "$manifest" <<'PY'
import json
import os
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
current_json = os.environ.get('CURRENT_JSON', '[]')
current = json.loads(current_json or '[]')


def parse_spec(spec: str):
    if spec.startswith('@'):
        if spec.count('@') >= 2:
            name, version = spec.rsplit('@', 1)
            return name, version
        return spec, None
    if '@' in spec:
        name, version = spec.rsplit('@', 1)
        return name, version
    return spec, None

manifest_specs = []
manifest_names = set()
for raw in manifest_path.read_text().splitlines():
    spec = raw.strip()
    if not spec or spec.startswith('#'):
        continue
    name, version = parse_spec(spec)
    manifest_specs.append((spec, name, version))
    manifest_names.add(name)

installed = {}
for entry in current:
    for name, meta in entry.get('dependencies', {}).items():
        installed[name] = meta.get('version')

install = []
for spec, name, version in manifest_specs:
    current_version = installed.get(name)
    if current_version is None or (version is not None and current_version != version):
        install.append(spec)

remove = sorted(name for name in installed if name not in manifest_names)
print(json.dumps({'install': install, 'remove': remove}))
PY
)"

plan_export="$($python_cmd - "$plan_json" <<'PY'
import json
import shlex
import sys

plan = json.loads(sys.argv[1])
for key in ('install', 'remove'):
    quoted = ' '.join(shlex.quote(item) for item in plan[key])
    print(f'{key.upper()}_SPECS=({quoted})')
PY
)"
eval "$plan_export"

if (( ${#INSTALL_SPECS[@]} == 0 && ${#REMOVE_SPECS[@]} == 0 )); then
  printf 'pnpm globals: up to date\n'
  exit 0
fi

printf 'pnpm globals manifest: %s\n' "$manifest"

if (( ${#REMOVE_SPECS[@]} > 0 )); then
  printf 'pnpm globals to remove:\n'
  printf '  - %s\n' "${REMOVE_SPECS[@]}"
fi

if (( ${#INSTALL_SPECS[@]} > 0 )); then
  printf 'pnpm globals to install/update:\n'
  printf '  - %s\n' "${INSTALL_SPECS[@]}"
fi

if [[ "$dry_run" -eq 1 ]]; then
  exit 0
fi

if (( ${#REMOVE_SPECS[@]} > 0 )); then
  "$pnpm_cmd" remove -g "${REMOVE_SPECS[@]}"
fi

if (( ${#INSTALL_SPECS[@]} > 0 )); then
  "$pnpm_cmd" add -g "${INSTALL_SPECS[@]}"
fi

printf 'pnpm globals: sync complete\n'
