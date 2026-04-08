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
Usage: scripts/secrets add-host [options]

Add a new host to secrets policy, explicitly choose user-scope membership,
sync .sops.yaml, then rekey and verify the resulting secret access.

Options:
  --host NAME            Override the host alias
  --recipient AGE1...    Use this host recipient instead of the local host key
  --class NAME           Set host metadata class (default: workstation)
  --user-scope NAME      Add the host to this user scope (repeatable)
  --no-user-scopes       Do not add the host to any user scope
  --dry-run              Show the intended changes only
  --yes                  Skip confirmation prompts
  -h, --help             Show this help
EOF
}

host_name="$(hostname -s)"
local_host_name="$(hostname -s)"
host_recipient=""
host_class="workstation"
dry_run=0
assume_yes=0
no_user_scopes=0
selected_user_scopes=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      host_name="${2:?missing value for --host}"
      shift 2
      ;;
    --recipient)
      host_recipient="${2:?missing value for --recipient}"
      shift 2
      ;;
    --class)
      host_class="${2:?missing value for --class}"
      shift 2
      ;;
    --user-scope)
      selected_user_scopes+=("${2:?missing value for --user-scope}")
      shift 2
      ;;
    --no-user-scopes)
      no_user_scopes=1
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

if [[ "${no_user_scopes}" -eq 1 && "${#selected_user_scopes[@]}" -gt 0 ]]; then
  secrets_ui_error "Use either --user-scope or --no-user-scopes, not both."
  exit 1
fi

secrets_inspect_state "${host_name}"

if [[ "${SECRETS_HOST_ALIAS_EXISTS}" -eq 1 ]]; then
  secrets_ui_error "Host ${host_name} already exists in ${SECRETS_POLICY_FILE}. Use scripts/secrets register-host instead."
  exit 1
fi

if [[ -n "${host_recipient}" && "${host_recipient}" != age1* ]]; then
  secrets_ui_error "Host recipient must start with age1."
  exit 1
fi

if [[ "${dry_run}" -ne 1 ]] && [[ -z "${host_recipient}" ]] \
  && [[ "${SECRETS_HOST_KEY_EXISTS}" -ne 1 || "${SECRETS_OPERATOR_KEY_EXISTS}" -ne 1 ]]; then
  secrets_ui_note "Bootstrapping missing onboarding age keys before host registration."
  bash "${script_dir}/ssh-pubkey-to-age.sh"
  secrets_inspect_state "${host_name}"
fi

if [[ -z "${host_recipient}" ]]; then
  if [[ "${SECRETS_HOST_KEY_EXISTS}" -ne 1 ]]; then
    secrets_ui_error "Missing host key: ${SECRETS_HOST_KEY_FILE}"
    exit 1
  fi

  if [[ -z "${SECRETS_HOST_PUBLIC_KEY}" ]]; then
    secrets_ui_error "Could not read the host public key from ${SECRETS_HOST_KEY_FILE}. Run scripts/secrets doctor --full-test if elevated inspection is needed."
    exit 1
  fi

  host_recipient="${SECRETS_HOST_PUBLIC_KEY}"
elif [[ "${host_name}" == "${local_host_name}" && -n "${SECRETS_HOST_PUBLIC_KEY}" \
  && "${host_recipient}" != "${SECRETS_HOST_PUBLIC_KEY}" ]]; then
  secrets_ui_error "Supplied recipient does not match the local host key for ${host_name}."
  exit 1
fi

mapfile -t available_user_scopes < <(secrets_list_user_scopes)

if [[ "${no_user_scopes}" -ne 1 && "${#selected_user_scopes[@]}" -eq 0 ]]; then
  if [[ "${#available_user_scopes[@]}" -gt 0 && -t 0 ]]; then
    mapfile -t selected_user_scopes < <(
      secrets_ui_choose_many \
        "Choose user scopes this host should join:" \
        "${available_user_scopes[@]}"
    )
  elif [[ "${#available_user_scopes[@]}" -gt 0 ]]; then
    secrets_ui_error "Explicit user-scope membership is required. Pass --user-scope ... or --no-user-scopes."
    exit 1
  fi
fi

if [[ "${#selected_user_scopes[@]}" -gt 0 ]]; then
  mapfile -t selected_user_scopes < <(printf '%s\n' "${selected_user_scopes[@]}" | sort -u)
fi

for scope_name in "${selected_user_scopes[@]}"; do
  if ! printf '%s\n' "${available_user_scopes[@]}" | grep -Fxq "${scope_name}"; then
    secrets_ui_error "Unknown user scope: ${scope_name}"
    exit 1
  fi
done

planned_secret_files=()
for scope_name in "${selected_user_scopes[@]}"; do
  scope_dir="${SECRETS_REPO_ROOT}/secrets/users/${scope_name}"
  if [[ -d "${scope_dir}" ]]; then
    while IFS= read -r secret_file; do
      planned_secret_files+=("${secret_file}")
    done < <(find "${scope_dir}" -type f -name '*.yaml' 2>/dev/null | sort)
  fi
done

machine_secret_dir="${SECRETS_REPO_ROOT}/secrets/machines/${host_name}"
if [[ -d "${machine_secret_dir}" ]]; then
  while IFS= read -r secret_file; do
    planned_secret_files+=("${secret_file}")
  done < <(
    find "${machine_secret_dir}" -type f \
      \( -name '*.yaml' -o -name '*.json' -o -name '*.env' -o -name '*.ini' \) \
      2>/dev/null | sort
  )
fi

if [[ "${#planned_secret_files[@]}" -gt 0 ]]; then
  mapfile -t planned_secret_files < <(printf '%s\n' "${planned_secret_files[@]}" | sort -u)

  if ! secrets_require_readable_age_identity "${SECRETS_OPERATOR_KEY_FILE}" "Operator age key" >/dev/null; then
    secrets_ui_error "Missing valid readable operator age key after onboarding bootstrap: ${SECRETS_OPERATOR_KEY_FILE}"
    exit 1
  fi

  for secret_file in "${planned_secret_files[@]}"; do
    if ! secrets_can_decrypt_with_key "${SECRETS_OPERATOR_KEY_FILE}" "${secret_file}"; then
      secrets_ui_error "Operator key cannot decrypt ${secret_file#${SECRETS_REPO_ROOT}/}"
      exit 1
    fi
  done
fi

secrets_ui_section "Add Host"
secrets_ui_kv "Host alias" "${host_name}"
secrets_ui_kv "Host class" "${host_class}"
secrets_ui_kv "Host recipient" "${host_recipient}"
printf '\nUser scopes to join:\n'
if [[ "${#selected_user_scopes[@]}" -eq 0 ]]; then
  printf '  (none)\n'
else
  printf '  %s\n' "${selected_user_scopes[@]}"
fi
printf '\nSecrets to rekey and verify:\n'
if [[ "${#planned_secret_files[@]}" -eq 0 ]]; then
  printf '  (none)\n'
else
  printf '  %s\n' "${planned_secret_files[@]#${SECRETS_REPO_ROOT}/}"
fi

if [[ "${dry_run}" -eq 1 ]]; then
  printf '\nDry run plan:\n'
  printf '  - add host %s -> %s to flake/secrets-policy.nix\n' "${host_name}" "${host_recipient}"
  printf '  - set host class to %s\n' "${host_class}"
  if [[ "${#selected_user_scopes[@]}" -gt 0 ]]; then
    printf '  - add %s to user scopes: %s\n' "${host_name}" "$(printf '%s ' "${selected_user_scopes[@]}" | sed 's/ $//')"
  else
    printf '  - leave user-scope membership unchanged\n'
  fi
  printf '  - regenerate .sops.yaml from policy\n'
  if [[ "${#planned_secret_files[@]}" -gt 0 ]]; then
    printf '  - rekey the listed secrets and verify host decryption\n'
  fi
  exit 0
fi

if [[ "${assume_yes}" -ne 1 ]] && ! secrets_ui_confirm "Add ${host_name} with the selected user-scope membership?"; then
  printf 'Aborted.\n'
  exit 1
fi

secrets_update_policy_host_recipient "${host_name}" "${host_recipient}" 1 "${host_class}"
for scope_name in "${selected_user_scopes[@]}"; do
  mapfile -t scope_hosts < <(secrets_get_user_scope_hosts "${scope_name}")
  scope_hosts+=("${host_name}")
  mapfile -t scope_hosts < <(printf '%s\n' "${scope_hosts[@]}" | sort -u)
  secrets_set_user_scope_hosts "${scope_name}" 0 "${scope_hosts[@]}"
done
secrets_sync_sops_config

printf '\nUpdated policy and regenerated .sops.yaml for %s.\n' "${host_name}"

register_args=(--host "${host_name}")
bash "${script_dir}/register-sops-host.sh" "${register_args[@]}"

printf '\nRunning post-change validation...\n'
bash "${workflow_dir}/validate-policy.sh"
bash "${workflow_dir}/validate.sh" --actor all --host "${host_name}"
