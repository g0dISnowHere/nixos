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
Usage: scripts/secrets recover-access [options]

Recover operator access from a machine that can still decrypt the target
secrets, then rekey those secrets to the intended operator recipient.

Options:
  --host NAME                    Target host whose relevant secrets to recover
  --source-key-file PATH         Existing working private key to use for rekey
  --target-operator-key-file PATH
                                 Read the target operator recipient from a key file
  --target-operator-recipient AGE1...
                                 Target operator recipient public key
  --dry-run                      Show the intended changes only
  --yes                          Skip confirmation prompts
  -h, --help                     Show this help
EOF
}

host_name="$(hostname -s)"
host_explicit=0
source_key_file=""
target_operator_key_file=""
target_operator_recipient=""
dry_run=0
assume_yes=0
target_operator_recipients=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      host_name="${2:?missing value for --host}"
      host_explicit=1
      shift 2
      ;;
    --source-key-file)
      source_key_file="${2:?missing value for --source-key-file}"
      shift 2
      ;;
    --target-operator-key-file)
      target_operator_key_file="${2:?missing value for --target-operator-key-file}"
      shift 2
      ;;
    --target-operator-recipient)
      target_operator_recipient="${2:?missing value for --target-operator-recipient}"
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

if [[ "${host_explicit}" -ne 1 ]]; then
  if [[ ! -f "${SECRETS_POLICY_FILE}" ]]; then
    secrets_ui_error "Missing secrets policy: ${SECRETS_POLICY_FILE}"
    exit 1
  fi

  available_hosts=()
  operator_alias="$(secrets_operator_alias)"
  while IFS= read -r alias_name; do
    if [[ -n "${alias_name}" && "${alias_name}" != "${operator_alias}" ]]; then
      available_hosts+=("${alias_name}")
    fi
  done < <(secrets_list_key_aliases)

  if [[ "${#available_hosts[@]}" -eq 0 ]]; then
    secrets_ui_error "No host aliases were found in ${SECRETS_POLICY_FILE}"
    exit 1
  fi

  if [[ " ${available_hosts[*]} " == *" ${host_name} "* ]]; then
    prompt_options=("${host_name}")
    for alias_name in "${available_hosts[@]}"; do
      if [[ "${alias_name}" != "${host_name}" ]]; then
        prompt_options+=("${alias_name}")
      fi
    done
    host_name="$(secrets_ui_choose "Choose the target host to recover access for:" "${prompt_options[@]}")"
  else
    host_name="$(secrets_ui_choose "Choose the target host to recover access for:" "${available_hosts[@]}")"
  fi
fi

secrets_inspect_state "${host_name}"

if [[ ! -f "${SECRETS_POLICY_FILE}" ]]; then
  secrets_ui_error "Missing secrets policy: ${SECRETS_POLICY_FILE}"
  exit 1
fi

if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -eq 0 ]]; then
  secrets_ui_error "No relevant secrets were found for host ${host_name}."
  exit 1
fi

if [[ -n "${target_operator_key_file}" ]]; then
  target_operator_recipient="$(secrets_read_public_key "${target_operator_key_file}" || true)"
  if [[ -z "${target_operator_recipient}" ]]; then
    secrets_ui_error "Could not read a public key from ${target_operator_key_file}"
    exit 1
  fi
fi

if [[ -z "${target_operator_recipient}" ]]; then
  default_target_recipient=""
  if [[ "${SECRETS_OPERATOR_KEY_EXISTS}" -eq 1 ]]; then
    default_target_recipient="$(secrets_read_public_key "${SECRETS_OPERATOR_KEY_FILE}" || true)"
  fi
  target_operator_recipient="$(secrets_ui_prompt \
    "Enter the target operator recipient (age1...)" \
    "${default_target_recipient}")"
fi

if [[ -z "${target_operator_recipient}" ]]; then
  secrets_ui_error "A target operator recipient is required."
  exit 1
fi

if [[ -n "${SECRETS_OPERATOR_PUBLIC_KEYS:-}" ]]; then
  while IFS= read -r existing_recipient; do
    if [[ -n "${existing_recipient}" ]]; then
      target_operator_recipients+=("${existing_recipient}")
    fi
  done < <(printf '%s\n' "${SECRETS_OPERATOR_PUBLIC_KEYS}" | tr ',' '\n' | sed 's/^ *//; s/ *$//')
fi

if [[ "${SECRETS_OPERATOR_KEY_EXISTS}" -eq 1 ]]; then
  while IFS= read -r local_recipient; do
    if [[ -n "${local_recipient}" ]]; then
      target_operator_recipients+=("${local_recipient}")
    fi
  done < <(secrets_read_public_keys "${SECRETS_OPERATOR_KEY_FILE}" || true)
fi

target_operator_recipients+=("${target_operator_recipient}")
mapfile -t target_operator_recipients < <(printf '%s\n' "${target_operator_recipients[@]}" | sed '/^$/d' | sort -u)

working_candidates=()
if [[ -n "${source_key_file}" ]]; then
  working_candidates=("${source_key_file}")
else
  if [[ "${SECRETS_OPERATOR_KEY_EXISTS}" -eq 1 ]]; then
    working_candidates+=("${SECRETS_OPERATOR_KEY_FILE}")
  fi
  if [[ "${SECRETS_HOST_KEY_EXISTS}" -eq 1 ]]; then
    working_candidates+=("${SECRETS_HOST_KEY_FILE}")
  fi
fi

usable_candidates=()
candidate=""
for candidate in "${working_candidates[@]}"; do
  if [[ -r "${candidate}" || -f "${candidate}" ]]; then
    if secrets_key_matches_recipient_set "${candidate}" "$(printf '%s\n' "${SECRETS_RELEVANT_RECIPIENTS[@]}")"; then
      if secrets_can_decrypt_with_key "${candidate}" "${SECRETS_RELEVANT_SECRETS[0]}"; then
        usable_candidates+=("${candidate}")
      fi
    fi
  fi
done

if [[ "${#usable_candidates[@]}" -eq 0 ]]; then
  secrets_ui_error "No working source key was detected on this machine for the target secrets."
  if [[ "${#SECRETS_RELEVANT_RECIPIENTS[@]}" -gt 0 ]]; then
    printf 'Relevant embedded recipients:\n' >&2
    printf '  %s\n' "${SECRETS_RELEVANT_RECIPIENTS[@]}" >&2
  fi
  exit 1
fi

if [[ -z "${source_key_file}" ]]; then
  if [[ "${#usable_candidates[@]}" -eq 1 ]]; then
    source_key_file="${usable_candidates[0]}"
  else
    source_key_file="$(secrets_ui_choose \
      "Multiple working keys were detected. Choose the source key to use:" \
      "${usable_candidates[@]}")"
  fi
fi

for candidate in "${SECRETS_RELEVANT_SECRETS[@]}"; do
  if ! secrets_can_decrypt_with_key "${source_key_file}" "${candidate}"; then
    secrets_ui_error "Source key ${source_key_file} cannot decrypt ${candidate#${SECRETS_REPO_ROOT}/}"
    exit 1
  fi
done

operator_alias="$(secrets_operator_alias)"

secrets_ui_section "Recover Access"
secrets_ui_kv "Target host" "${host_name}"
secrets_ui_kv "Source key file" "${source_key_file}"
secrets_ui_kv "Target operator alias" "${operator_alias}"
secrets_ui_kv "Target recipient" "${target_operator_recipient}"
secrets_ui_kv "Final operator recipients" "$(printf '%s ' "${target_operator_recipients[@]}" | sed 's/ $//')"
printf '\nAffected secrets:\n'
printf '  %s\n' "${SECRETS_RELEVANT_SECRETS[@]#${SECRETS_REPO_ROOT}/}"

if [[ "${dry_run}" -eq 1 ]]; then
  printf '\nDry run plan:\n'
  printf '  - update operator recipients in flake/secrets-policy.nix for %s\n' "${operator_alias}"
  printf '  - regenerate .sops.yaml from policy\n'
  printf '  - rekey the listed secrets using %s\n' "${source_key_file}"
  if [[ -n "${target_operator_key_file}" ]]; then
    printf '  - validate decrypt with %s\n' "${target_operator_key_file}"
  else
    printf '  - validation of the target key will happen later on the destination machine\n'
  fi
  exit 0
fi

if [[ "${assume_yes}" -ne 1 ]] && ! secrets_ui_confirm "Update policy and rekey the listed secrets?"; then
  printf 'Aborted.\n'
  exit 1
fi

secrets_update_policy_operator_recipient "${target_operator_recipients[@]}"
secrets_sync_sops_config
printf '\nUpdated policy and regenerated .sops.yaml operator recipients.\n'

for candidate in "${SECRETS_RELEVANT_SECRETS[@]}"; do
  printf 'Rekeying %s\n' "${candidate#${SECRETS_REPO_ROOT}/}"
  SOPS_AGE_KEY_FILE="${source_key_file}" sops updatekeys --yes "${candidate}"
done

if [[ -n "${target_operator_key_file}" ]]; then
  for candidate in "${SECRETS_RELEVANT_SECRETS[@]}"; do
    printf 'Validating target operator key against %s\n' "${candidate#${SECRETS_REPO_ROOT}/}"
    SOPS_AGE_KEY_FILE="${target_operator_key_file}" sops --decrypt "${candidate}" >/dev/null
  done
  printf '\nRecovered operator access and validated the target key.\n'
else
  printf '\nRecovered operator access metadata.\n'
  printf 'Validation still needs to run on the destination machine with the target private key:\n'
  printf '  scripts/secrets validate-access --actor operator --host %s\n' "${host_name}"
fi
