#!/usr/bin/env bash

set -euo pipefail

workflow_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_dir="$(cd "${workflow_dir}/.." && pwd)"

# shellcheck source=../secrets-lib/inspect.sh
source "${script_dir}/secrets-lib/inspect.sh"
# shellcheck source=../secrets-lib/ui.sh
source "${script_dir}/secrets-lib/ui.sh"

usage() {
  cat <<'EOF'
Usage: scripts/secrets validate [options]

Validate operator and/or host access to the relevant secrets for a host.

Options:
  --actor NAME    operator, host, or all (default: all)
  --host NAME     Override the host alias
  -h, --help      Show this help
EOF
}

actor="all"
host_name="$(hostname -s)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --actor)
      actor="${2:?missing value for --actor}"
      shift 2
      ;;
    --host)
      host_name="${2:?missing value for --host}"
      shift 2
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

case "${actor}" in
  operator|host|all)
    ;;
  *)
    printf 'Unknown actor: %s\n' "${actor}" >&2
    exit 1
    ;;
esac

secrets_inspect_state "${host_name}"

secrets_ui_section "Secrets Validation"
secrets_ui_kv "Host alias" "${SECRETS_HOST_NAME}"
secrets_ui_kv "Relevant secrets" "${SECRETS_RELEVANT_SECRET_COUNT}"
printf '\n'

if [[ "${actor}" == "operator" || "${actor}" == "all" ]]; then
  if [[ "${SECRETS_OPERATOR_KEY_EXISTS}" -ne 1 ]]; then
    secrets_ui_error "Operator key file is missing or unreadable: ${SECRETS_OPERATOR_KEY_FILE}"
    exit 1
  fi

  if [[ "${SECRETS_OPERATOR_CAN_DECRYPT}" -eq 1 ]]; then
    printf 'operator: ok\n'
  else
    printf 'operator: failed\n'
    if [[ "${#SECRETS_OPERATOR_FAILED_SECRETS[@]}" -gt 0 ]]; then
      printf '  %s\n' "${SECRETS_OPERATOR_FAILED_SECRETS[@]#${SECRETS_REPO_ROOT}/}"
    fi
    exit 1
  fi
fi

if [[ "${actor}" == "host" || "${actor}" == "all" ]]; then
  if [[ "${SECRETS_HOST_KEY_EXISTS}" -ne 1 ]]; then
    secrets_ui_error "Host key file is missing: ${SECRETS_HOST_KEY_FILE}"
    exit 1
  fi

  if [[ "${SECRETS_HOST_CAN_DECRYPT}" -eq 1 ]]; then
    printf 'host: ok\n'
  else
    printf 'host: failed\n'
    if [[ "${#SECRETS_HOST_FAILED_SECRETS[@]}" -gt 0 ]]; then
      printf '  %s\n' "${SECRETS_HOST_FAILED_SECRETS[@]#${SECRETS_REPO_ROOT}/}"
    fi
    exit 1
  fi
fi
