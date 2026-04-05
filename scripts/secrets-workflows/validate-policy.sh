#!/usr/bin/env bash

set -euo pipefail

workflow_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_dir="$(cd "${workflow_dir}/.." && pwd)"

# shellcheck source=../secrets-lib/inspect.sh
source "${script_dir}/secrets-lib/inspect.sh"
# shellcheck source=../secrets-lib/ui.sh
source "${script_dir}/secrets-lib/ui.sh"

secrets_inspect_state "$(hostname -s)"

secrets_ui_section "Secrets Policy Validation"
secrets_ui_kv "Policy file" "${SECRETS_POLICY_FILE}"
secrets_ui_kv "Rendered config" "${SECRETS_SOPS_CONFIG}"
printf '\n'

if [[ "${SECRETS_POLICY_ERROR_COUNT}" -gt 0 ]]; then
  secrets_ui_error "Policy validation failed."
  printf 'Errors:\n'
  printf '  %s\n' "${SECRETS_POLICY_ERRORS[@]}"
  exit 1
fi

if [[ "${SECRETS_POLICY_DRIFT}" -eq 1 ]]; then
  secrets_ui_error "Committed .sops.yaml does not match rendered policy."
  exit 1
fi

printf 'policy: ok\n'
