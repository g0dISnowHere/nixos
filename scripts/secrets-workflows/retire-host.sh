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
Usage: scripts/secrets retire-host [options]

Remove a host from secrets policy and rekey shared secrets to drop its access.

Options:
  --host NAME      Host alias to retire
  --dry-run        Show the intended changes only
  --yes            Skip confirmation prompts
  -h, --help       Show this help
EOF
}

host_name=""
dry_run=0
assume_yes=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      host_name="${2:?missing value for --host}"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --yes)
      assume_yes=1
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

if [[ -z "${host_name}" ]]; then
  mapfile -t available_hosts < <(secrets_policy_tool list-hosts)
  if [[ "${#available_hosts[@]}" -eq 0 ]]; then
    secrets_ui_error "No hosts are defined in ${SECRETS_POLICY_FILE}"
    exit 1
  fi
  host_name="$(secrets_ui_choose "Choose the host to retire:" "${available_hosts[@]}")"
fi

secrets_inspect_state "${host_name}"

if [[ "${SECRETS_HOST_ALIAS_EXISTS}" -ne 1 ]]; then
  secrets_ui_error "Host ${host_name} is not defined in ${SECRETS_POLICY_FILE}"
  exit 1
fi

machine_secret_dir="${SECRETS_REPO_ROOT}/secrets/machines/${host_name}"
machine_secret_files=()
if [[ -d "${machine_secret_dir}" ]]; then
  mapfile -t machine_secret_files < <(
    find "${machine_secret_dir}" -type f \
      \( -name '*.yaml' -o -name '*.json' -o -name '*.env' -o -name '*.ini' \) \
      2>/dev/null | sort
  )
fi

if [[ "${#machine_secret_files[@]}" -gt 0 ]]; then
  secrets_ui_error "Refusing to retire ${host_name} while machine-scoped secrets still exist."
  printf 'Machine-scoped secrets to remove or migrate first:\n' >&2
  printf '  %s\n' "${machine_secret_files[@]#${SECRETS_REPO_ROOT}/}" >&2
  exit 1
fi

shared_secret_files=()
for secret_file in "${SECRETS_RELEVANT_SECRETS[@]}"; do
  if [[ "${secret_file}" != "${machine_secret_dir}/"* ]]; then
    shared_secret_files+=("${secret_file}")
  fi
done

if [[ "${#shared_secret_files[@]}" -gt 0 ]]; then
  if ! secrets_require_readable_age_identity "${SECRETS_OPERATOR_KEY_FILE}" "Operator age key" >/dev/null; then
    secrets_ui_error "Missing valid readable operator age key: ${SECRETS_OPERATOR_KEY_FILE}"
    exit 1
  fi

  for secret_file in "${shared_secret_files[@]}"; do
    if ! secrets_can_decrypt_with_key "${SECRETS_OPERATOR_KEY_FILE}" "${secret_file}"; then
      secrets_ui_error "Operator key cannot decrypt ${secret_file#${SECRETS_REPO_ROOT}/}"
      exit 1
    fi
  done
fi

secrets_ui_section "Retire Host"
secrets_ui_kv "Host" "${host_name}"
secrets_ui_kv "Configured recipient" "${SECRETS_CONFIGURED_HOST_RECIPIENT}"
printf '\nShared secrets to rekey:\n'
if [[ "${#shared_secret_files[@]}" -eq 0 ]]; then
  printf '  (none)\n'
else
  printf '  %s\n' "${shared_secret_files[@]#${SECRETS_REPO_ROOT}/}"
fi

if [[ "${dry_run}" -eq 1 ]]; then
  printf '\nDry run plan:\n'
  printf '  - remove %s from flake/secrets-policy.nix\n' "${host_name}"
  printf '  - regenerate .sops.yaml from policy\n'
  if [[ "${#shared_secret_files[@]}" -gt 0 ]]; then
    printf '  - rekey the listed shared secrets to drop %s access\n' "${host_name}"
  fi
  exit 0
fi

if [[ "${assume_yes}" -ne 1 ]] && ! secrets_ui_confirm "Retire ${host_name} and remove its shared secret access?"; then
  printf 'Aborted.\n'
  exit 1
fi

python3 "${SECRETS_POLICY_TOOL}" \
  remove-host \
  --policy-file "${SECRETS_POLICY_FILE}" \
  --host "${host_name}"
unset SECRETS_POLICY_JSON
secrets_sync_sops_config

for secret_file in "${shared_secret_files[@]}"; do
  printf 'Rekeying %s\n' "${secret_file#${SECRETS_REPO_ROOT}/}"
  SOPS_AGE_KEY_FILE="${SECRETS_OPERATOR_KEY_FILE}" sops updatekeys --yes "${secret_file}"
done

bash "${workflow_dir}/validate-policy.sh"
printf 'Retired host %s from secrets policy.\n' "${host_name}"
