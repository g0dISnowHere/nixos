#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=secrets-lib/inspect.sh
source "${script_dir}/secrets-lib/inspect.sh"

usage() {
  cat <<'EOF'
Usage: scripts/register-sops-host.sh [options]

Rekey the selected host's relevant secrets from policy and verify host access.

Options:
  --host NAME               Override the host alias in flake/secrets-policy.nix
  --dry-run                 Show what would change without writing
  --force-host-rotate       Allow changing an existing host recipient
  -h, --help                Show this help
EOF
}

host_name="$(hostname -s)"
dry_run=0
force_host_rotate=0

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
    --force-host-rotate)
      force_host_rotate=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

secrets_inspect_state "${host_name}"

if [[ "${SECRETS_HOST_ALIAS_EXISTS}" -ne 1 ]]; then
  printf 'Host %s is missing from flake/secrets-policy.nix\n' "${host_name}" >&2
  exit 1
fi

if [[ "${SECRETS_HOST_KEY_EXISTS}" -ne 1 ]]; then
  printf 'Missing host sops-nix key: %s\n' "${SECRETS_HOST_KEY_FILE}" >&2
  exit 1
fi

if [[ "${SECRETS_HOST_RECIPIENT_MATCHES}" -ne 1 && "${force_host_rotate}" -ne 1 ]]; then
  printf 'Host recipient mismatch detected.\n' >&2
  printf 'Refusing to proceed without --force-host-rotate.\n' >&2
  exit 1
fi

if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -gt 0 ]]; then
  if ! secrets_require_readable_age_identity "${SECRETS_OPERATOR_KEY_FILE}" "Operator age key" >/dev/null; then
    printf 'Missing valid readable operator age key: %s\n' "${SECRETS_OPERATOR_KEY_FILE}" >&2
    exit 1
  fi

  if [[ "${SECRETS_OPERATOR_CAN_DECRYPT}" -ne 1 ]]; then
    printf 'The operator key cannot decrypt the current target secrets.\n' >&2
    if [[ "${#SECRETS_OPERATOR_FAILED_SECRETS[@]}" -gt 0 ]]; then
      printf 'Blocked files:\n' >&2
      printf '  %s\n' "${SECRETS_OPERATOR_FAILED_SECRETS[@]#${SECRETS_REPO_ROOT}/}" >&2
    fi
    exit 1
  fi
fi

printf 'Host alias: %s\n' "${host_name}"
printf 'Configured recipient: %s\n' "${SECRETS_CONFIGURED_HOST_RECIPIENT}"
printf 'Host key recipient: %s\n' "${SECRETS_HOST_PUBLIC_KEY}"
printf '\nSecrets to rekey and verify:\n'
if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -eq 0 ]]; then
  printf '  (none)\n'
else
  printf '  %s\n' "${SECRETS_RELEVANT_SECRETS[@]#${SECRETS_REPO_ROOT}/}"
fi

if [[ "${dry_run}" -eq 1 ]]; then
  if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -gt 0 ]]; then
    printf '\nWould run sops updatekeys on the listed secrets.\n'
    printf 'Would verify host decryption with SOPS_AGE_KEY_FILE=%s.\n' "${SECRETS_HOST_KEY_FILE}"
  fi
  exit 0
fi

for secret_file in "${SECRETS_RELEVANT_SECRETS[@]}"; do
  printf 'Rekeying %s\n' "${secret_file#${SECRETS_REPO_ROOT}/}"
  SOPS_AGE_KEY_FILE="${SECRETS_OPERATOR_KEY_FILE}" sops updatekeys --yes "${secret_file}"
done

for secret_file in "${SECRETS_RELEVANT_SECRETS[@]}"; do
  printf 'Verifying decrypt %s\n' "${secret_file#${SECRETS_REPO_ROOT}/}"
  SOPS_AGE_KEY_FILE="${SECRETS_HOST_KEY_FILE}" sops --decrypt "${secret_file}" >/dev/null
done

printf '\nHost secret registration succeeded for %s.\n' "${host_name}"
printf 'Next step:\n'
printf '  sudo nixos-rebuild test --flake .#%s\n' "${host_name}"
