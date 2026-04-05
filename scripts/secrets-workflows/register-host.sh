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
Usage: scripts/secrets register-host [options]

Refresh an existing host recipient in flake/secrets-policy.nix, sync .sops.yaml,
then rekey the relevant secrets and verify host decryption.

Options:
  --host NAME            Override the host alias
  --allow-create         Deprecated compatibility flag; use add-host instead
  --force-host-rotate    Allow changing an existing configured recipient
  --dry-run              Show the intended changes only
  --yes                  Skip confirmation prompts
  -h, --help             Show this help
EOF
}

host_name="$(hostname -s)"
allow_create=0
force_host_rotate=0
dry_run=0
assume_yes=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      host_name="${2:?missing value for --host}"
      shift 2
      ;;
    --allow-create)
      allow_create=1
      shift
      ;;
    --force-host-rotate)
      force_host_rotate=1
      shift
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

secrets_inspect_state "${host_name}"

if [[ "${SECRETS_HOST_KEY_EXISTS}" -ne 1 ]]; then
  secrets_ui_error "Missing host key: ${SECRETS_HOST_KEY_FILE}"
  exit 1
fi

if [[ -z "${SECRETS_HOST_PUBLIC_KEY}" ]]; then
  secrets_ui_error "Could not read the host public key from ${SECRETS_HOST_KEY_FILE}. Run scripts/secrets doctor --full-test if elevated inspection is needed."
  exit 1
fi

if [[ ! -f "${SECRETS_POLICY_FILE}" ]]; then
  secrets_ui_error "Missing secrets policy: ${SECRETS_POLICY_FILE}"
  exit 1
fi

if [[ "${SECRETS_HOST_ALIAS_EXISTS}" -ne 1 && "${allow_create}" -ne 1 ]]; then
  secrets_ui_error "Host ${host_name} is not in flake/secrets-policy.nix. Use scripts/secrets add-host."
  exit 1
fi

if [[ "${SECRETS_OPERATOR_KEY_EXISTS}" -ne 1 && "${SECRETS_RELEVANT_SECRET_COUNT}" -gt 0 ]]; then
  secrets_ui_error "Missing readable operator key file: ${SECRETS_OPERATOR_KEY_FILE}"
  exit 1
fi

if [[ "${SECRETS_OPERATOR_CAN_DECRYPT}" -ne 1 && "${SECRETS_RELEVANT_SECRET_COUNT}" -gt 0 ]]; then
  secrets_ui_error "The operator key cannot decrypt the current target secrets."
  if [[ "${#SECRETS_OPERATOR_FAILED_SECRETS[@]}" -gt 0 ]]; then
    printf 'Blocked files:\n' >&2
    printf '  %s\n' "${SECRETS_OPERATOR_FAILED_SECRETS[@]#${SECRETS_REPO_ROOT}/}" >&2
  fi
  exit 1
fi

if [[ "${SECRETS_HOST_ALIAS_EXISTS}" -eq 1 \
  && "${SECRETS_HOST_RECIPIENT_MATCHES}" -ne 1 \
  && "${force_host_rotate}" -ne 1 ]]; then
  secrets_ui_error "Host recipient mismatch detected. Re-run with --force-host-rotate to accept the new host key."
  exit 1
fi

secrets_ui_section "Register Host"
secrets_ui_kv "Host alias" "${host_name}"
secrets_ui_kv "Host public key" "${SECRETS_HOST_PUBLIC_KEY}"

if [[ "${SECRETS_HOST_ALIAS_EXISTS}" -eq 1 ]]; then
  secrets_ui_kv "Configured recipient" "${SECRETS_CONFIGURED_HOST_RECIPIENT}"
else
  secrets_ui_kv "Configured recipient" "host missing from policy"
fi

printf '\nRelevant secrets:\n'
if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -eq 0 ]]; then
  printf '  (none)\n'
else
  printf '  %s\n' "${SECRETS_RELEVANT_SECRETS[@]#${SECRETS_REPO_ROOT}/}"
fi

if [[ "${SECRETS_HOST_ALIAS_EXISTS}" -ne 1 ]]; then
  if [[ "${allow_create}" -eq 1 ]]; then
    secrets_ui_error "register-host --allow-create is deprecated. Use scripts/secrets add-host for explicit onboarding."
  else
    secrets_ui_error "Host ${host_name} is missing from policy. Use scripts/secrets add-host."
  fi
  exit 1
elif [[ "${SECRETS_HOST_RECIPIENT_MATCHES}" -ne 1 ]]; then
  if [[ "${dry_run}" -eq 1 ]]; then
    printf '\nWould update flake/secrets-policy.nix and regenerate .sops.yaml.\n'
    exit 0
  fi

  secrets_update_policy_host_recipient "${host_name}" "${SECRETS_HOST_PUBLIC_KEY}" 0
  secrets_sync_sops_config
  printf '\nUpdated policy recipient and regenerated .sops.yaml for %s.\n' "${host_name}"
fi

register_args=(--host "${host_name}")
if [[ "${dry_run}" -eq 1 ]]; then
  register_args+=(--dry-run)
fi
if [[ "${force_host_rotate}" -eq 1 ]]; then
  register_args+=(--force-host-rotate)
fi

printf '\nRunning register-sops-host.sh...\n'
bash "${script_dir}/register-sops-host.sh" "${register_args[@]}"

printf '\nRunning post-change validation...\n'
bash "${workflow_dir}/validate-policy.sh"
bash "${workflow_dir}/validate.sh" --actor all --host "${host_name}"
