#!/usr/bin/env bash

set -euo pipefail

SECRETS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_SCRIPT_DIR="$(cd "${SECRETS_LIB_DIR}/.." && pwd)"
SECRETS_REPO_ROOT="$(cd "${SECRETS_SCRIPT_DIR}/.." && pwd)"
SECRETS_SOPS_CONFIG="${SECRETS_REPO_ROOT}/.sops.yaml"
SECRETS_HOST_KEY_FILE="/var/lib/sops-nix/key.txt"
SECRETS_OPERATOR_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

secrets_require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    printf '%s is required but not on PATH\n' "${cmd}" >&2
    exit 1
  fi
}

secrets_read_public_key() {
  local key_file="$1"

  if [[ -r "${key_file}" ]]; then
    grep '^# public key:' "${key_file}" | awk '{print $4}' | head -n 1
  elif [[ -f "${key_file}" ]]; then
    sudo -n grep '^# public key:' "${key_file}" 2>/dev/null | awk '{print $4}' | head -n 1
  fi
}

secrets_read_public_keys() {
  local key_file="$1"

  if [[ -r "${key_file}" ]]; then
    grep '^# public key:' "${key_file}" | awk '{print $4}'
  fi
}

secrets_config_host_recipient() {
  local host_name="$1"

  python3 - "${SECRETS_SOPS_CONFIG}" "${host_name}" <<'PY'
import re
import sys

path, host = sys.argv[1], sys.argv[2]
pattern = re.compile(rf"^(\s*-\s*&{re.escape(host)}\s+)(age1[0-9a-z]+)\s*$")

with open(path, "r", encoding="utf-8") as fh:
    for line in fh:
        match = pattern.match(line)
        if match:
            print(match.group(2))
            raise SystemExit(0)

raise SystemExit(1)
PY
}

secrets_first_key_alias() {
  python3 - "${SECRETS_SOPS_CONFIG}" <<'PY'
import re
import sys

path = sys.argv[1]
pattern = re.compile(r"^\s*-\s*&([A-Za-z0-9_-]+)\s+age1[0-9a-z]+\s*$")

with open(path, "r", encoding="utf-8") as fh:
    for line in fh:
        match = pattern.match(line)
        if match:
            print(match.group(1))
            raise SystemExit(0)

raise SystemExit(1)
PY
}

secrets_list_key_aliases() {
  python3 - "${SECRETS_SOPS_CONFIG}" <<'PY'
import re
import sys

path = sys.argv[1]
pattern = re.compile(r"^\s*-\s*&([A-Za-z0-9_-]+)\s+age1[0-9a-z]+\s*$")

with open(path, "r", encoding="utf-8") as fh:
    for line in fh:
        match = pattern.match(line)
        if match:
            print(match.group(1))
PY
}

secrets_update_key_alias_recipient() {
  local alias_name="$1"
  local recipient="$2"

  python3 - "${SECRETS_SOPS_CONFIG}" "${alias_name}" "${recipient}" <<'PY'
import re
import sys

path, alias_name, recipient = sys.argv[1:4]
pattern = re.compile(rf"^(\s*-\s*&{re.escape(alias_name)}\s+)(age1[0-9a-z]+)\s*$", re.M)

with open(path, "r", encoding="utf-8") as fh:
    content = fh.read()

updated, count = pattern.subn(rf"\1{recipient}", content, count=1)
if count != 1:
    raise SystemExit(f"missing alias: {alias_name}")

with open(path, "w", encoding="utf-8") as fh:
    fh.write(updated)
PY
}

secrets_list_relevant_files() {
  local host_name="$1"

  {
    find "${SECRETS_REPO_ROOT}/secrets/users" -type f -name '*.yaml' 2>/dev/null
    find "${SECRETS_REPO_ROOT}/secrets/services/shared" -type f \
      \( -name '*.yaml' -o -name '*.json' -o -name '*.env' -o -name '*.ini' \) \
      ! -name '*.example' 2>/dev/null
    find "${SECRETS_REPO_ROOT}/secrets/machines/${host_name}" -type f \
      \( -name '*.yaml' -o -name '*.json' -o -name '*.env' -o -name '*.ini' \) \
      2>/dev/null
  } | sort -u
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

secrets_ensure_operator_access() {
  local key_file="$1"
  local secret_file="$2"

  if ! secrets_can_decrypt_with_key "${key_file}" "${secret_file}"; then
    printf 'Cannot decrypt %s with operator key %s\n' \
      "${secret_file#${SECRETS_REPO_ROOT}/}" "${key_file}" >&2
    return 1
  fi
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

secrets_add_host_to_config() {
  local host_name="$1"
  local recipient="$2"
  local operator_alias="$3"

  python3 - "${SECRETS_SOPS_CONFIG}" "${host_name}" "${recipient}" "${operator_alias}" <<'PY'
import sys

path, host, recipient, operator_alias = sys.argv[1:5]

with open(path, "r", encoding="utf-8") as fh:
    lines = fh.readlines()

host_anchor = f"          - *{host}\n"
operator_anchor = f"          - *{operator_alias}\n"
host_key_line = f"  - &{host} {recipient}\n"
machine_rule = f"  - path_regex: ^secrets/machines/{host}/.*\\.(yaml|json|env|ini)$\n"

if any(line.startswith(f"  - &{host} ") for line in lines):
    raise SystemExit("host alias already exists")

creation_idx = None
for idx, line in enumerate(lines):
    if line.startswith("creation_rules:"):
      creation_idx = idx
      break

if creation_idx is None:
    raise SystemExit("missing creation_rules section")

insert_key_at = creation_idx
while insert_key_at > 0 and lines[insert_key_at - 1].startswith("  - &"):
    insert_key_at -= 1
last_key_idx = creation_idx
for idx in range(insert_key_at, creation_idx):
    if lines[idx].startswith("  - &"):
        last_key_idx = idx + 1

lines.insert(last_key_idx, host_key_line)

def find_rule_index(prefix):
    for idx, line in enumerate(lines):
        if line.strip() == f"- path_regex: {prefix}":
            return idx
    return None

def add_alias_to_rule(path_regex, alias):
    rule_idx = find_rule_index(path_regex)
    if rule_idx is None:
        raise SystemExit(f"missing rule: {path_regex}")
    next_rule = len(lines)
    for idx in range(rule_idx + 1, len(lines)):
        if lines[idx].startswith("  - path_regex:"):
            next_rule = idx
            break

    anchor_line = f"          - *{alias}\n"
    if anchor_line in lines[rule_idx:next_rule]:
        return

    insert_at = None
    for idx in range(rule_idx + 1, next_rule):
        if lines[idx].startswith("          - *"):
            insert_at = idx + 1

    if insert_at is None:
        raise SystemExit(f"missing age list for rule: {path_regex}")

    lines.insert(insert_at, anchor_line)

add_alias_to_rule(r"^secrets/users/djoolz/.*\.yaml$", host)
add_alias_to_rule(r"^secrets/services/shared/.*\.(yaml|json|env|ini)$", host)

machine_idx = find_rule_index(rf"^secrets/machines/{host}/.*\.(yaml|json|env|ini)$")
if machine_idx is None:
    shared_idx = find_rule_index(r"^secrets/services/shared/.*\.(yaml|json|env|ini)$")
    if shared_idx is None:
        raise SystemExit("missing shared services rule")
    block = [
        machine_rule,
        "    key_groups:\n",
        "      - age:\n",
        operator_anchor,
        host_anchor,
    ]
    lines[shared_idx:shared_idx] = block
else:
    add_alias_to_rule(rf"^secrets/machines/{host}/.*\.(yaml|json|env|ini)$", operator_alias)
    add_alias_to_rule(rf"^secrets/machines/{host}/.*\.(yaml|json|env|ini)$", host)

with open(path, "w", encoding="utf-8") as fh:
    fh.writelines(lines)
PY
}

secrets_inspect_state() {
  local host_name="$1"
  local operator_failures=()
  local host_failures=()
  local secret_file=""

  for cmd in awk find grep hostname python3 sops sort sudo; do
    secrets_require_command "${cmd}"
  done

  SECRETS_HOST_NAME="${host_name}"
  SECRETS_RELEVANT_SECRETS=()
  mapfile -t SECRETS_RELEVANT_SECRETS < <(secrets_list_relevant_files "${host_name}")
  SECRETS_RELEVANT_SECRET_COUNT="${#SECRETS_RELEVANT_SECRETS[@]}"
  SECRETS_RELEVANT_RECIPIENTS=()
  if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -gt 0 ]]; then
    mapfile -t SECRETS_RELEVANT_RECIPIENTS < <(secrets_list_secret_recipients "${SECRETS_RELEVANT_SECRETS[@]}")
  fi

  SECRETS_OPERATOR_KEY_EXISTS=0
  SECRETS_OPERATOR_KEY_STATUS="missing"
  SECRETS_OPERATOR_PUBLIC_KEYS=""
  if [[ -r "${SECRETS_OPERATOR_KEY_FILE}" ]]; then
    SECRETS_OPERATOR_KEY_EXISTS=1
    SECRETS_OPERATOR_KEY_STATUS="readable"
    SECRETS_OPERATOR_PUBLIC_KEYS="$(secrets_read_public_keys "${SECRETS_OPERATOR_KEY_FILE}" | paste -sd ', ' -)"
  fi

  SECRETS_HOST_KEY_EXISTS=0
  SECRETS_HOST_KEY_STATUS="missing"
  SECRETS_HOST_PUBLIC_KEY=""
  if [[ -f "${SECRETS_HOST_KEY_FILE}" ]]; then
    SECRETS_HOST_KEY_EXISTS=1
    if [[ -r "${SECRETS_HOST_KEY_FILE}" ]]; then
      SECRETS_HOST_KEY_STATUS="readable"
    else
      SECRETS_HOST_KEY_STATUS="present but unreadable"
    fi
    SECRETS_HOST_PUBLIC_KEY="$(secrets_read_public_key "${SECRETS_HOST_KEY_FILE}" || true)"
  fi

  SECRETS_HOST_ALIAS_EXISTS=0
  SECRETS_CONFIGURED_HOST_RECIPIENT=""
  if [[ -f "${SECRETS_SOPS_CONFIG}" ]]; then
    if SECRETS_CONFIGURED_HOST_RECIPIENT="$(secrets_config_host_recipient "${host_name}" 2>/dev/null || true)"; then
      if [[ -n "${SECRETS_CONFIGURED_HOST_RECIPIENT}" ]]; then
        SECRETS_HOST_ALIAS_EXISTS=1
      fi
    fi
  fi

  SECRETS_HOST_RECIPIENT_MATCHES=0
  if [[ -n "${SECRETS_HOST_PUBLIC_KEY}" && -n "${SECRETS_CONFIGURED_HOST_RECIPIENT}" \
    && "${SECRETS_HOST_PUBLIC_KEY}" == "${SECRETS_CONFIGURED_HOST_RECIPIENT}" ]]; then
    SECRETS_HOST_RECIPIENT_MATCHES=1
  fi

  SECRETS_OPERATOR_CAN_DECRYPT=0
  SECRETS_OPERATOR_DECRYPT_STATUS="skipped"
  if [[ "${SECRETS_OPERATOR_KEY_EXISTS}" -eq 1 ]]; then
    if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -eq 0 ]]; then
      SECRETS_OPERATOR_CAN_DECRYPT=1
      SECRETS_OPERATOR_DECRYPT_STATUS="no relevant secrets"
    else
      for secret_file in "${SECRETS_RELEVANT_SECRETS[@]}"; do
        if ! secrets_can_decrypt_with_key "${SECRETS_OPERATOR_KEY_FILE}" "${secret_file}"; then
          operator_failures+=("${secret_file}")
        fi
      done
      if [[ "${#operator_failures[@]}" -eq 0 ]]; then
        SECRETS_OPERATOR_CAN_DECRYPT=1
        SECRETS_OPERATOR_DECRYPT_STATUS="ok"
      else
        SECRETS_OPERATOR_DECRYPT_STATUS="failed (${#operator_failures[@]})"
      fi
    fi
  else
    SECRETS_OPERATOR_DECRYPT_STATUS="operator key unavailable"
  fi
  SECRETS_OPERATOR_FAILED_SECRETS=("${operator_failures[@]}")

  SECRETS_HOST_CAN_DECRYPT=0
  SECRETS_HOST_DECRYPT_STATUS="skipped"
  if [[ "${SECRETS_HOST_KEY_EXISTS}" -eq 1 ]]; then
    if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -eq 0 ]]; then
      SECRETS_HOST_CAN_DECRYPT=1
      SECRETS_HOST_DECRYPT_STATUS="no relevant secrets"
    else
      for secret_file in "${SECRETS_RELEVANT_SECRETS[@]}"; do
        if ! secrets_can_decrypt_with_key "${SECRETS_HOST_KEY_FILE}" "${secret_file}"; then
          host_failures+=("${secret_file}")
        fi
      done
      if [[ "${#host_failures[@]}" -eq 0 ]]; then
        SECRETS_HOST_CAN_DECRYPT=1
        SECRETS_HOST_DECRYPT_STATUS="ok"
      else
        SECRETS_HOST_DECRYPT_STATUS="failed (${#host_failures[@]})"
      fi
    fi
  else
    SECRETS_HOST_DECRYPT_STATUS="host key unavailable"
  fi
  SECRETS_HOST_FAILED_SECRETS=("${host_failures[@]}")
}
