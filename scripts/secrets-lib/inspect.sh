#!/usr/bin/env bash

set -euo pipefail

SECRETS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_SCRIPT_DIR="$(cd "${SECRETS_LIB_DIR}/.." && pwd)"
SECRETS_REPO_ROOT="$(cd "${SECRETS_SCRIPT_DIR}/.." && pwd)"
SECRETS_SOPS_CONFIG="${SECRETS_REPO_ROOT}/.sops.yaml"
SECRETS_HOST_KEY_FILE="/var/lib/sops-nix/key.txt"
SECRETS_OPERATOR_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
SECRETS_ALLOW_SUDO_PROMPT="${SECRETS_ALLOW_SUDO_PROMPT:-0}"

# shellcheck source=policy.sh
source "${SECRETS_LIB_DIR}/policy.sh"

secrets_require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    printf '%s is required but not on PATH\n' "${cmd}" >&2
    exit 1
  fi
}

secrets_sudo_read() {
  if [[ "${SECRETS_ALLOW_SUDO_PROMPT}" -eq 1 ]]; then
    sudo "$@"
  else
    sudo -n "$@" 2>/dev/null
  fi
}

secrets_capture_public_key() {
  local key_file="$1"
  local output=""

  SECRETS_LAST_KEY_READ_MODE="none"
  SECRETS_LAST_PUBLIC_KEY=""

  if [[ -r "${key_file}" ]]; then
    output="$(grep '^# public key:' "${key_file}" | awk '{print $4}' | head -n 1)"
    if [[ -n "${output}" ]]; then
      SECRETS_LAST_KEY_READ_MODE="direct"
      SECRETS_LAST_PUBLIC_KEY="${output}"
    fi
    return 0
  fi

  if [[ -f "${key_file}" ]]; then
    output="$(secrets_sudo_read grep '^# public key:' "${key_file}" | awk '{print $4}' | head -n 1 || true)"
    if [[ -n "${output}" ]]; then
      SECRETS_LAST_KEY_READ_MODE="elevated"
      SECRETS_LAST_PUBLIC_KEY="${output}"
    fi
  fi
}

secrets_read_public_key() {
  local key_file="$1"

  secrets_capture_public_key "${key_file}"
  printf '%s\n' "${SECRETS_LAST_PUBLIC_KEY}"
}

secrets_read_public_keys() {
  local key_file="$1"

  if [[ -r "${key_file}" ]]; then
    grep '^# public key:' "${key_file}" | awk '{print $4}'
  fi
}

secrets_operator_alias() {
  secrets_policy_tool get-operator-alias
}

secrets_operator_recipients() {
  secrets_policy_tool get-operator-recipients
}

secrets_config_host_recipient() {
  local host_name="$1"
  secrets_policy_tool get-host-recipient --host "${host_name}" 2>/dev/null || true
}

secrets_list_key_aliases() {
  local operator_alias

  operator_alias="$(secrets_operator_alias)"
  printf '%s\n' "${operator_alias}"
  secrets_policy_tool list-hosts
}

secrets_list_user_scopes() {
  secrets_policy_tool list-user-scopes
}

secrets_get_user_scope_hosts() {
  local user_name="$1"
  secrets_policy_tool get-user-scope-hosts --user "${user_name}"
}

secrets_list_relevant_files() {
  local host_name="$1"
  secrets_policy_tool list-relevant-files --repo-root "${SECRETS_REPO_ROOT}" --host "${host_name}"
}

secrets_list_secret_recipients() {
  if [[ "$#" -eq 0 ]]; then
    return 0
  fi

  grep -hE 'recipient: age1[0-9a-z]+' "$@" 2>/dev/null \
    | awk '{print $3}' \
    | sort -u
}

secrets_key_matches_recipient_set() {
  local key_file="$1"
  local recipient_list="$2"
  local public_key=""

  public_key="$(secrets_read_public_key "${key_file}" || true)"
  if [[ -z "${public_key}" ]]; then
    return 1
  fi

  grep -Fxq "${public_key}" <<< "${recipient_list}"
}

secrets_can_decrypt_with_key() {
  local key_file="$1"
  local secret_file="$2"

  SOPS_AGE_KEY_FILE="${key_file}" sops --decrypt "${secret_file}" >/dev/null 2>&1
}

secrets_collect_failed_decrypts() {
  local key_file="$1"
  shift
  local failed=()
  local secret_file=""

  for secret_file in "$@"; do
    if ! secrets_can_decrypt_with_key "${key_file}" "${secret_file}"; then
      failed+=("${secret_file}")
    fi
  done

  printf '%s\n' "${failed[@]:-}"
}

secrets_validate_policy_json() {
  secrets_policy_tool validate --repo-root "${SECRETS_REPO_ROOT}"
}

secrets_update_policy_host_recipient() {
  local host_name="$1"
  local recipient="$2"
  local create_flag="${3:-0}"
  local args=(
    "${SECRETS_POLICY_TOOL}"
    set-host-recipient
    --policy-file "${SECRETS_POLICY_FILE}"
    --host "${host_name}"
    --recipient "${recipient}"
  )

  if [[ "${create_flag}" -eq 1 ]]; then
    args+=(--create)
  fi


  python3 "${args[@]}"
  unset SECRETS_POLICY_JSON
}

secrets_update_policy_operator_recipient() {
  local args=(
    "${SECRETS_POLICY_TOOL}"
    set-operator-recipient
    --policy-file "${SECRETS_POLICY_FILE}"
  )
  local recipient=""
  for recipient in "$@"; do
    args+=(--recipient "${recipient}")
  done
  python3 "${args[@]}"
  unset SECRETS_POLICY_JSON
}

secrets_set_user_scope_hosts() {
  local user_name="$1"
  shift
  local create_flag="${1:-0}"
  shift || true
  local args=(
    "${SECRETS_POLICY_TOOL}"
    set-user-scope-hosts
    --policy-file "${SECRETS_POLICY_FILE}"
    --user "${user_name}"
  )

  if [[ "${create_flag}" -eq 1 ]]; then
    args+=(--create)
  fi

  local host_name=""
  for host_name in "$@"; do
    args+=(--host "${host_name}")
  done

  python3 "${args[@]}"
  unset SECRETS_POLICY_JSON
}

secrets_remove_user_scope() {
  local user_name="$1"
  python3 "${SECRETS_POLICY_TOOL}" \
    remove-user-scope \
    --policy-file "${SECRETS_POLICY_FILE}" \
    --user "${user_name}"
  unset SECRETS_POLICY_JSON
}

secrets_inspect_state() {
  local host_name="$1"
  local inspect_actor="${2:-all}"
  local inspect_operator=0
  local inspect_host=0
  local secret_file=""
  local policy_validation_json=""
  case "${inspect_actor}" in
    operator)
      inspect_operator=1
      ;;
    host)
      inspect_host=1
      ;;
    all)
      inspect_operator=1
      inspect_host=1
      ;;
    *)
      printf 'Unknown inspect actor: %s\n' "${inspect_actor}" >&2
      return 1
      ;;
  esac

  local operator_failures=()
  local host_failures=()

  for cmd in awk find grep hostname nix python3 sops sort sudo; do
    secrets_require_command "${cmd}"
  done

  secrets_load_policy_json

  SECRETS_HOST_NAME="${host_name}"
  SECRETS_OPERATOR_ALIAS="$(secrets_operator_alias)"
  SECRETS_RELEVANT_SECRETS=()
  mapfile -t SECRETS_RELEVANT_SECRETS < <(secrets_list_relevant_files "${host_name}")
  SECRETS_RELEVANT_SECRET_COUNT="${#SECRETS_RELEVANT_SECRETS[@]}"
  SECRETS_RELEVANT_RECIPIENTS=()
  if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -gt 0 ]]; then
    mapfile -t SECRETS_RELEVANT_RECIPIENTS < <(secrets_list_secret_recipients "${SECRETS_RELEVANT_SECRETS[@]}")
  fi

  SECRETS_POLICY_ERRORS=()
  if policy_validation_json="$(secrets_validate_policy_json 2>/dev/null || true)"; then
    :
  fi
  if [[ -n "${policy_validation_json}" ]]; then
    mapfile -t SECRETS_POLICY_ERRORS < <(
      python3 - "${policy_validation_json}" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
for error in payload.get("errors", []):
    print(error)
PY
    )
  fi
  SECRETS_POLICY_ERROR_COUNT="${#SECRETS_POLICY_ERRORS[@]}"

  SECRETS_POLICY_DRIFT=0
  if [[ -f "${SECRETS_SOPS_CONFIG}" ]]; then
    if [[ "$(secrets_render_sops_config)" != "$(cat "${SECRETS_SOPS_CONFIG}")" ]]; then
      SECRETS_POLICY_DRIFT=1
    fi
  else
    SECRETS_POLICY_DRIFT=1
  fi

  export SECRETS_OPERATOR_KEY_EXISTS=0
  export SECRETS_OPERATOR_KEY_PRESENCE_STATUS="missing"
  export SECRETS_OPERATOR_KEY_INSPECTION_STATUS="unavailable"
  export SECRETS_OPERATOR_KEY_STATUS="missing"
  export SECRETS_OPERATOR_PUBLIC_KEYS=""
  if [[ "${inspect_operator}" -eq 1 ]]; then
    if [[ -r "${SECRETS_OPERATOR_KEY_FILE}" ]]; then
      export SECRETS_OPERATOR_KEY_EXISTS=1
      export SECRETS_OPERATOR_KEY_PRESENCE_STATUS="present"
      export SECRETS_OPERATOR_KEY_INSPECTION_STATUS="readable"
      export SECRETS_OPERATOR_KEY_STATUS="readable"
      SECRETS_OPERATOR_PUBLIC_KEYS="$(secrets_read_public_keys "${SECRETS_OPERATOR_KEY_FILE}" | paste -sd ', ' -)"
      export SECRETS_OPERATOR_PUBLIC_KEYS
    elif [[ -f "${SECRETS_OPERATOR_KEY_FILE}" ]]; then
      export SECRETS_OPERATOR_KEY_EXISTS=1
      export SECRETS_OPERATOR_KEY_PRESENCE_STATUS="present"
      export SECRETS_OPERATOR_KEY_INSPECTION_STATUS="unreadable"
      export SECRETS_OPERATOR_KEY_STATUS="present but unreadable"
    fi
  fi

  export SECRETS_HOST_KEY_EXISTS=0
  export SECRETS_HOST_KEY_PRESENCE_STATUS="missing"
  export SECRETS_HOST_KEY_INSPECTION_STATUS="unavailable"
  export SECRETS_HOST_KEY_STATUS="missing"
  export SECRETS_HOST_PUBLIC_KEY=""
  export SECRETS_LAST_PUBLIC_KEY=""
  if [[ "${inspect_host}" -eq 1 && -f "${SECRETS_HOST_KEY_FILE}" ]]; then
    export SECRETS_HOST_KEY_EXISTS=1
    export SECRETS_HOST_KEY_PRESENCE_STATUS="present"
    if [[ -r "${SECRETS_HOST_KEY_FILE}" ]]; then
      export SECRETS_HOST_KEY_INSPECTION_STATUS="direct"
      export SECRETS_HOST_KEY_STATUS="readable"
    else
      export SECRETS_HOST_KEY_INSPECTION_STATUS="direct access unavailable"
      export SECRETS_HOST_KEY_STATUS="present but unreadable"
    fi
    secrets_capture_public_key "${SECRETS_HOST_KEY_FILE}"
    export SECRETS_HOST_PUBLIC_KEY="${SECRETS_LAST_PUBLIC_KEY}"
    case "${SECRETS_LAST_KEY_READ_MODE}" in
      direct)
        export SECRETS_HOST_KEY_INSPECTION_STATUS="direct"
        ;;
      elevated)
        export SECRETS_HOST_KEY_INSPECTION_STATUS="elevated-only"
        ;;
      *)
        ;;
    esac
  fi

  export SECRETS_HOST_ALIAS_EXISTS=0
  export SECRETS_CONFIGURED_HOST_RECIPIENT=""
  if SECRETS_CONFIGURED_HOST_RECIPIENT="$(secrets_config_host_recipient "${host_name}")"; then
    if [[ -n "${SECRETS_CONFIGURED_HOST_RECIPIENT}" ]]; then
      export SECRETS_HOST_ALIAS_EXISTS=1
    fi
  fi

  export SECRETS_HOST_RECIPIENT_MATCH_STATUS="unknown"
  export SECRETS_HOST_RECIPIENT_MATCHES=0
  if [[ -n "${SECRETS_HOST_PUBLIC_KEY}" && -n "${SECRETS_CONFIGURED_HOST_RECIPIENT}" \
    && "${SECRETS_HOST_PUBLIC_KEY}" == "${SECRETS_CONFIGURED_HOST_RECIPIENT}" ]]; then
    export SECRETS_HOST_RECIPIENT_MATCH_STATUS="yes"
    export SECRETS_HOST_RECIPIENT_MATCHES=1
  elif [[ -n "${SECRETS_HOST_PUBLIC_KEY}" && -n "${SECRETS_CONFIGURED_HOST_RECIPIENT}" ]]; then
    export SECRETS_HOST_RECIPIENT_MATCH_STATUS="no"
  fi

  export SECRETS_OPERATOR_CAN_DECRYPT=0
  export SECRETS_OPERATOR_KEY_DECRYPT_STATUS="unavailable"
  export SECRETS_OPERATOR_DECRYPT_STATUS="skipped"
  if [[ "${inspect_operator}" -eq 1 ]]; then
    if [[ "${SECRETS_OPERATOR_KEY_EXISTS}" -eq 1 ]]; then
      if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -eq 0 ]]; then
        export SECRETS_OPERATOR_CAN_DECRYPT=1
        export SECRETS_OPERATOR_KEY_DECRYPT_STATUS="ok"
        export SECRETS_OPERATOR_DECRYPT_STATUS="no relevant secrets"
      else
        for secret_file in "${SECRETS_RELEVANT_SECRETS[@]}"; do
          if ! secrets_can_decrypt_with_key "${SECRETS_OPERATOR_KEY_FILE}" "${secret_file}"; then
            operator_failures+=("${secret_file}")
          fi
        done
        if [[ "${#operator_failures[@]}" -eq 0 ]]; then
          export SECRETS_OPERATOR_CAN_DECRYPT=1
          export SECRETS_OPERATOR_KEY_DECRYPT_STATUS="ok"
          export SECRETS_OPERATOR_DECRYPT_STATUS="ok"
        else
          export SECRETS_OPERATOR_KEY_DECRYPT_STATUS="failed"
          export SECRETS_OPERATOR_DECRYPT_STATUS="failed (${#operator_failures[@]})"
        fi
      fi
    else
      export SECRETS_OPERATOR_KEY_DECRYPT_STATUS="unavailable"
      export SECRETS_OPERATOR_DECRYPT_STATUS="operator key unavailable"
    fi
  fi
  SECRETS_OPERATOR_FAILED_SECRETS=("${operator_failures[@]}")

  export SECRETS_HOST_CAN_DECRYPT=0
  export SECRETS_HOST_KEY_DECRYPT_STATUS="unavailable"
  export SECRETS_HOST_DECRYPT_STATUS="skipped"
  if [[ "${inspect_host}" -eq 1 ]]; then
    if [[ "${SECRETS_HOST_KEY_EXISTS}" -eq 1 ]]; then
      if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -eq 0 ]]; then
        export SECRETS_HOST_CAN_DECRYPT=1
        export SECRETS_HOST_KEY_DECRYPT_STATUS="ok"
        export SECRETS_HOST_DECRYPT_STATUS="no relevant secrets"
      else
        for secret_file in "${SECRETS_RELEVANT_SECRETS[@]}"; do
          if ! secrets_can_decrypt_with_key "${SECRETS_HOST_KEY_FILE}" "${secret_file}"; then
            host_failures+=("${secret_file}")
          fi
        done
        if [[ "${#host_failures[@]}" -eq 0 ]]; then
          export SECRETS_HOST_CAN_DECRYPT=1
          export SECRETS_HOST_KEY_DECRYPT_STATUS="ok"
          export SECRETS_HOST_DECRYPT_STATUS="ok"
        else
          export SECRETS_HOST_KEY_DECRYPT_STATUS="failed"
          export SECRETS_HOST_DECRYPT_STATUS="failed (${#host_failures[@]})"
        fi
      fi
    else
      export SECRETS_HOST_KEY_DECRYPT_STATUS="unavailable"
      export SECRETS_HOST_DECRYPT_STATUS="host key unavailable"
    fi
  fi
  SECRETS_HOST_FAILED_SECRETS=("${host_failures[@]}")

  : \
    "${SECRETS_HOST_NAME}" \
    "${SECRETS_OPERATOR_ALIAS}" \
    "${SECRETS_RELEVANT_RECIPIENTS[@]}" \
    "${SECRETS_POLICY_ERRORS[@]}" \
    "${SECRETS_POLICY_ERROR_COUNT}" \
    "${SECRETS_POLICY_DRIFT}" \
    "${SECRETS_OPERATOR_KEY_EXISTS}" \
    "${SECRETS_OPERATOR_KEY_PRESENCE_STATUS}" \
    "${SECRETS_OPERATOR_KEY_INSPECTION_STATUS}" \
    "${SECRETS_OPERATOR_KEY_STATUS}" \
    "${SECRETS_OPERATOR_PUBLIC_KEYS}" \
    "${SECRETS_HOST_KEY_EXISTS}" \
    "${SECRETS_HOST_KEY_PRESENCE_STATUS}" \
    "${SECRETS_HOST_KEY_INSPECTION_STATUS}" \
    "${SECRETS_HOST_KEY_STATUS}" \
    "${SECRETS_HOST_PUBLIC_KEY}" \
    "${SECRETS_LAST_PUBLIC_KEY}" \
    "${SECRETS_HOST_ALIAS_EXISTS}" \
    "${SECRETS_CONFIGURED_HOST_RECIPIENT}" \
    "${SECRETS_HOST_RECIPIENT_MATCH_STATUS}" \
    "${SECRETS_HOST_RECIPIENT_MATCHES}" \
    "${SECRETS_OPERATOR_CAN_DECRYPT}" \
    "${SECRETS_OPERATOR_KEY_DECRYPT_STATUS}" \
    "${SECRETS_OPERATOR_DECRYPT_STATUS}" \
    "${SECRETS_OPERATOR_FAILED_SECRETS[@]}" \
    "${SECRETS_HOST_CAN_DECRYPT}" \
    "${SECRETS_HOST_KEY_DECRYPT_STATUS}" \
    "${SECRETS_HOST_DECRYPT_STATUS}" \
    "${SECRETS_HOST_FAILED_SECRETS[@]}"
}
