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
Usage: scripts/secrets rotate-host [options]

Replace an existing host recipient with the current target-host key, then rekey
and validate the affected secrets.

Options:
  --host NAME      Host alias to rotate (default: current host)
  --dry-run        Show the intended changes only
  --yes            Skip confirmation prompts
  -h, --help       Show this help
EOF
}

host_name="$(hostname -s)"
local_host_name="$(hostname -s)"
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

if [[ "${host_name}" != "${local_host_name}" ]]; then
  secrets_ui_section "Rotate Host Key"
  secrets_ui_note "This workflow must run on the target host because it reads ${SECRETS_HOST_KEY_FILE} there."
  secrets_ui_kv "Target host" "${host_name}"
  printf '\nRun this on the target host:\n'
  printf '  scripts/secrets rotate-host --host %s\n' "${host_name}"
  exit 0
fi

secrets_inspect_state "${host_name}"

if [[ "${SECRETS_HOST_ALIAS_EXISTS}" -ne 1 ]]; then
  secrets_ui_error "Host ${host_name} is not in ${SECRETS_POLICY_FILE}. Use scripts/secrets add-host for onboarding."
  exit 1
fi

if [[ "${SECRETS_HOST_KEY_EXISTS}" -ne 1 ]]; then
  secrets_ui_error "Missing host key: ${SECRETS_HOST_KEY_FILE}"
  exit 1
fi

if [[ -z "${SECRETS_HOST_PUBLIC_KEY}" ]]; then
  secrets_ui_error "Could not read the host public key from ${SECRETS_HOST_KEY_FILE}. Run scripts/secrets doctor --full-test if elevated inspection is needed."
  exit 1
fi

secrets_ui_section "Rotate Host Key"
secrets_ui_kv "Host alias" "${host_name}"
secrets_ui_kv "Current recipient" "${SECRETS_CONFIGURED_HOST_RECIPIENT}"
secrets_ui_kv "Target recipient" "${SECRETS_HOST_PUBLIC_KEY}"
printf '\nAffected secrets:\n'
if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -eq 0 ]]; then
  printf '  (none)\n'
else
  printf '  %s\n' "${SECRETS_RELEVANT_SECRETS[@]#${SECRETS_REPO_ROOT}/}"
fi

if [[ "${dry_run}" -eq 1 ]]; then
  printf '\nDry run plan:\n'
  printf '  - update %s in flake/secrets-policy.nix to %s\n' "${host_name}" "${SECRETS_HOST_PUBLIC_KEY}"
  printf '  - regenerate .sops.yaml from policy\n'
  if [[ "${SECRETS_RELEVANT_SECRET_COUNT}" -gt 0 ]]; then
    printf '  - rekey the listed secrets and validate host access\n'
  fi
  bash "${workflow_dir}/register-host.sh" --host "${host_name}" --force-host-rotate --dry-run
  exit 0
fi

if [[ "${assume_yes}" -ne 1 ]] && ! secrets_ui_confirm "Rotate ${host_name} to the current host key and rekey the affected secrets?"; then
  printf 'Aborted.\n'
  exit 1
fi

bash "${workflow_dir}/register-host.sh" --host "${host_name}" --force-host-rotate
