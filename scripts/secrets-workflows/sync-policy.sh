#!/usr/bin/env bash

set -euo pipefail

workflow_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_dir="$(cd "${workflow_dir}/.." && pwd)"

# shellcheck source=../secrets-lib/inspect.sh
source "${script_dir}/secrets-lib/inspect.sh"

usage() {
  cat <<'EOF'
Usage: scripts/secrets sync-policy [--check] [--diff]
EOF
}

check_only=0
show_diff=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      check_only=1
      shift
      ;;
    --diff)
      show_diff=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

rendered="$(secrets_render_sops_config)"
current=""
if [[ -f "${SECRETS_SOPS_CONFIG}" ]]; then
  current="$(cat "${SECRETS_SOPS_CONFIG}")"
fi

if [[ "${show_diff}" -eq 1 ]]; then
  diff -u <(printf '%s' "${current}") <(printf '%s' "${rendered}") || true
fi

if [[ "${check_only}" -eq 1 ]]; then
  if [[ "${current}" != "${rendered}" ]]; then
    printf '.sops.yaml is out of sync with flake/secrets-policy.nix\n' >&2
    exit 1
  fi
  printf 'policy sync: ok\n'
  exit 0
fi

secrets_sync_sops_config
printf 'updated %s\n' "${SECRETS_SOPS_CONFIG}"
