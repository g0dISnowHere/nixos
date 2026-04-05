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
Usage: scripts/secrets user-scope [options]

Create, update, or retire a users.<name> policy entry and rekey affected user
secrets when membership changes.

Options:
  --user NAME            User scope name
  --host NAME            Set the exact host membership (repeatable)
  --add-host NAME        Add a host to the existing membership (repeatable)
  --remove-host NAME     Remove a host from the existing membership (repeatable)
  --create               Allow creating a missing user scope
  --retire               Remove the user scope from policy
  --dry-run              Show the intended changes only
  --yes                  Skip confirmation prompts
  -h, --help             Show this help
EOF
}

user_name=""
dry_run=0
assume_yes=0
allow_create=0
retire_scope=0
exact_hosts=()
add_hosts=()
remove_hosts=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      user_name="${2:?missing value for --user}"
      shift 2
      ;;
    --host)
      exact_hosts+=("${2:?missing value for --host}")
      shift 2
      ;;
    --add-host)
      add_hosts+=("${2:?missing value for --add-host}")
      shift 2
      ;;
    --remove-host)
      remove_hosts+=("${2:?missing value for --remove-host}")
      shift 2
      ;;
    --create)
      allow_create=1
      shift
      ;;
    --retire)
      retire_scope=1
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

if [[ -z "${user_name}" ]]; then
  secrets_ui_error "--user is required."
  exit 1
fi

if [[ "${retire_scope}" -eq 1 && ( "${#exact_hosts[@]}" -gt 0 || "${#add_hosts[@]}" -gt 0 || "${#remove_hosts[@]}" -gt 0 || "${allow_create}" -eq 1 ) ]]; then
  secrets_ui_error "--retire cannot be combined with membership mutation options."
  exit 1
fi

if [[ "${#exact_hosts[@]}" -gt 0 && ( "${#add_hosts[@]}" -gt 0 || "${#remove_hosts[@]}" -gt 0 ) ]]; then
  secrets_ui_error "Use either --host for exact membership or --add-host/--remove-host for incremental changes."
  exit 1
fi

mapfile -t known_hosts < <(secrets_policy_tool list-hosts)
mapfile -t existing_user_scopes < <(secrets_list_user_scopes)

scope_exists=0
if printf '%s\n' "${existing_user_scopes[@]}" | grep -Fxq "${user_name}"; then
  scope_exists=1
fi

user_scope_dir="${SECRETS_REPO_ROOT}/secrets/users/${user_name}"
affected_secret_files=()
if [[ -d "${user_scope_dir}" ]]; then
  while IFS= read -r secret_file; do
    affected_secret_files+=("${secret_file}")
  done < <(find "${user_scope_dir}" -type f -name '*.yaml' 2>/dev/null | sort)
fi

if [[ "${retire_scope}" -eq 1 ]]; then
  if [[ "${scope_exists}" -ne 1 ]]; then
    secrets_ui_error "User scope ${user_name} is not defined in ${SECRETS_POLICY_FILE}"
    exit 1
  fi
  if [[ "${#affected_secret_files[@]}" -gt 0 ]]; then
    secrets_ui_error "Refusing to retire users.${user_name} while user-scoped secrets still exist."
    printf 'User-scoped secrets to remove or migrate first:\n' >&2
    printf '  %s\n' "${affected_secret_files[@]#${SECRETS_REPO_ROOT}/}" >&2
    exit 1
  fi

  secrets_ui_section "Retire User Scope"
  secrets_ui_kv "User scope" "users.${user_name}"

  if [[ "${dry_run}" -eq 1 ]]; then
    printf '\nDry run plan:\n'
    printf '  - remove users.%s from flake/secrets-policy.nix\n' "${user_name}"
    printf '  - regenerate .sops.yaml from policy\n'
    exit 0
  fi

  if [[ "${assume_yes}" -ne 1 ]] && ! secrets_ui_confirm "Retire users.${user_name} from secrets policy?"; then
    printf 'Aborted.\n'
    exit 1
  fi

  secrets_remove_user_scope "${user_name}"
  secrets_sync_sops_config
  bash "${workflow_dir}/validate-policy.sh"
  printf 'Retired users.%s from secrets policy.\n' "${user_name}"
  exit 0
fi

target_hosts=()
if [[ "${#exact_hosts[@]}" -gt 0 ]]; then
  target_hosts=("${exact_hosts[@]}")
elif [[ "${scope_exists}" -eq 1 ]]; then
  mapfile -t target_hosts < <(secrets_get_user_scope_hosts "${user_name}")
  target_hosts+=("${add_hosts[@]}")
  if [[ "${#remove_hosts[@]}" -gt 0 ]]; then
    remaining_hosts=()
    for host_name in "${target_hosts[@]}"; do
      if ! printf '%s\n' "${remove_hosts[@]}" | grep -Fxq "${host_name}"; then
        remaining_hosts+=("${host_name}")
      fi
    done
    target_hosts=("${remaining_hosts[@]}")
  fi
elif [[ "${allow_create}" -eq 1 ]]; then
  target_hosts=("${add_hosts[@]}")
else
  secrets_ui_error "User scope ${user_name} is not in ${SECRETS_POLICY_FILE}. Re-run with --create."
  exit 1
fi

if [[ "${#target_hosts[@]}" -gt 0 ]]; then
  mapfile -t target_hosts < <(printf '%s\n' "${target_hosts[@]}" | sort -u)
fi

for host_name in "${target_hosts[@]}"; do
  if ! printf '%s\n' "${known_hosts[@]}" | grep -Fxq "${host_name}"; then
    secrets_ui_error "Unknown host in membership set: ${host_name}"
    exit 1
  fi
done

if [[ "${#affected_secret_files[@]}" -gt 0 ]]; then
  if [[ ! -r "${SECRETS_OPERATOR_KEY_FILE}" ]]; then
    secrets_ui_error "Missing readable operator key file: ${SECRETS_OPERATOR_KEY_FILE}"
    exit 1
  fi

  for secret_file in "${affected_secret_files[@]}"; do
    if ! secrets_can_decrypt_with_key "${SECRETS_OPERATOR_KEY_FILE}" "${secret_file}"; then
      secrets_ui_error "Operator key cannot decrypt ${secret_file#${SECRETS_REPO_ROOT}/}"
      exit 1
    fi
  done
fi

secrets_ui_section "User Scope"
secrets_ui_kv "User scope" "users.${user_name}"
if [[ "${scope_exists}" -eq 1 ]]; then
  mapfile -t current_hosts < <(secrets_get_user_scope_hosts "${user_name}")
  secrets_ui_kv "Current hosts" "${current_hosts[*]:-(none)}"
else
  secrets_ui_kv "Current hosts" "(missing)"
fi
secrets_ui_kv "Target hosts" "${target_hosts[*]:-(none)}"
printf '\nAffected secrets:\n'
if [[ "${#affected_secret_files[@]}" -eq 0 ]]; then
  printf '  (none)\n'
else
  printf '  %s\n' "${affected_secret_files[@]#${SECRETS_REPO_ROOT}/}"
fi

if [[ "${dry_run}" -eq 1 ]]; then
  printf '\nDry run plan:\n'
  if [[ "${scope_exists}" -eq 1 ]]; then
    printf '  - update users.%s host membership in flake/secrets-policy.nix\n' "${user_name}"
  else
    printf '  - create users.%s in flake/secrets-policy.nix\n' "${user_name}"
  fi
  printf '  - set hosts to: %s\n' "${target_hosts[*]:-(none)}"
  printf '  - regenerate .sops.yaml from policy\n'
  if [[ "${#affected_secret_files[@]}" -gt 0 ]]; then
    printf '  - rekey the listed user-scoped secrets\n'
  fi
  exit 0
fi

if [[ "${assume_yes}" -ne 1 ]] && ! secrets_ui_confirm "Apply the users.${user_name} membership change?"; then
  printf 'Aborted.\n'
  exit 1
fi

create_flag=0
if [[ "${scope_exists}" -ne 1 ]]; then
  create_flag=1
fi
secrets_set_user_scope_hosts "${user_name}" "${create_flag}" "${target_hosts[@]}"
secrets_sync_sops_config

for secret_file in "${affected_secret_files[@]}"; do
  printf 'Rekeying %s\n' "${secret_file#${SECRETS_REPO_ROOT}/}"
  SOPS_AGE_KEY_FILE="${SECRETS_OPERATOR_KEY_FILE}" sops updatekeys --yes "${secret_file}"
done

bash "${workflow_dir}/validate-policy.sh"
printf 'Updated users.%s in secrets policy.\n' "${user_name}"
