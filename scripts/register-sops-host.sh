#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/register-sops-host.sh [options]

Register or refresh the current host's sops-nix machine recipient in .sops.yaml,
rekey the relevant secrets, and verify the host can decrypt them.

Options:
  --host NAME               Override the host alias in .sops.yaml
  --dry-run                 Show what would change without writing
  --force-host-rotate       Allow changing an existing host recipient
  -h, --help                Show this help

The script only updates the selected host entry in .sops.yaml. It does not
modify operator recipients or SSH keys.
EOF
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf '%s is required but not on PATH\n' "$cmd" >&2
    exit 1
  fi
}

read_host_public_key() {
  local key_file="$1"

  if [[ -r "${key_file}" ]]; then
    grep '^# public key:' "${key_file}" | awk '{print $4}'
  else
    sudo grep '^# public key:' "${key_file}" | awk '{print $4}'
  fi
}

read_age_public_keys() {
  local key_file="$1"

  if [[ -r "${key_file}" ]]; then
    grep '^# public key:' "${key_file}" | awk '{print $4}'
  fi
}

require_operator_decrypt_access() {
  local key_file="$1"
  local secret_file="$2"

  if ! SOPS_AGE_KEY_FILE="${key_file}" sops --decrypt "${secret_file}" >/dev/null 2>&1; then
    printf '\nCannot decrypt %s with the local operator key file.\n' \
      "${secret_file#${repo_root}/}" >&2
    printf 'Operator key file: %s\n' "${key_file}" >&2

    if [[ "${#operator_recipients[@]}" -gt 0 ]]; then
      printf 'Operator public keys loaded from that file:\n' >&2
      printf '  %s\n' "${operator_recipients[@]}" >&2
    else
      printf 'No operator public keys were found in %s\n' "${key_file}" >&2
    fi

    printf '\nThis script uses sops updatekeys, which requires a private key that\n' >&2
    printf 'can already decrypt the existing secret before recipients are changed.\n' >&2
    printf 'Fix the operator key file or recover/re-encrypt the secret with a valid\n' >&2
    printf 'existing recipient, then run this script again.\n' >&2
    exit 1
  fi
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sops_config="${repo_root}/.sops.yaml"
host_key_file="/var/lib/sops-nix/key.txt"
sops_age_key_file="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
host_name="$(hostname -s)"
dry_run=0
force_host_rotate=0
operator_recipients=()

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

for cmd in hostname grep find sort sops python3 sudo awk; do
  require_command "$cmd"
done

if [[ ! -f "${host_key_file}" ]]; then
  printf 'Missing host sops-nix key: %s\n' "${host_key_file}" >&2
  exit 1
fi

if [[ ! -f "${sops_config}" ]]; then
  printf 'Missing sops config: %s\n' "${sops_config}" >&2
  exit 1
fi

new_recipient="$(read_host_public_key "${host_key_file}")"
if [[ -z "${new_recipient}" ]]; then
  printf 'Could not read host recipient from %s\n' "${host_key_file}" >&2
  exit 1
fi

current_recipient="$(python3 - "${sops_config}" "${host_name}" <<'PY'
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
)" || {
  printf 'Host alias not found in .sops.yaml: %s\n' "${host_name}" >&2
  exit 1
}

printf 'Host alias: %s\n' "${host_name}"
printf 'Current recipient: %s\n' "${current_recipient}"
printf 'Host key recipient: %s\n' "${new_recipient}"

if [[ "${current_recipient}" != "${new_recipient}" && "${force_host_rotate}" -ne 1 ]]; then
  printf '\nHost recipient mismatch detected.\n' >&2
  printf 'Refusing to rewrite .sops.yaml without --force-host-rotate.\n' >&2
  exit 1
fi

mapfile -t secret_files < <(
  {
    find "${repo_root}/secrets/users" -type f -name '*.yaml' 2>/dev/null
    find "${repo_root}/secrets/services/shared" -type f \
      \( -name '*.yaml' -o -name '*.json' -o -name '*.env' -o -name '*.ini' \) \
      ! -name '*.example' 2>/dev/null
    find "${repo_root}/secrets/machines/${host_name}" -type f \
      \( -name '*.yaml' -o -name '*.json' -o -name '*.env' -o -name '*.ini' \) \
      2>/dev/null
  } | sort -u
)

printf '\nSecrets to rekey and verify:\n'
if [[ "${#secret_files[@]}" -eq 0 ]]; then
  printf '  (none)\n'
else
  printf '  %s\n' "${secret_files[@]#${repo_root}/}"
fi

if [[ -r "${sops_age_key_file}" ]]; then
  mapfile -t operator_recipients < <(read_age_public_keys "${sops_age_key_file}")
fi

if [[ "${dry_run}" -eq 1 ]]; then
  if [[ "${current_recipient}" != "${new_recipient}" ]]; then
    printf '\nWould update .sops.yaml: &%s -> %s\n' "${host_name}" "${new_recipient}"
  else
    printf '\n.sops.yaml already matches the host key.\n'
  fi

  if [[ "${#secret_files[@]}" -gt 0 ]]; then
    printf 'Would run sops updatekeys on the listed secrets.\n'
    printf 'Would verify host decryption with SOPS_AGE_KEY_FILE=%s.\n' "${host_key_file}"
  fi

  exit 0
fi

if [[ "${#secret_files[@]}" -gt 0 ]]; then
  if [[ ! -r "${sops_age_key_file}" ]]; then
    printf '\nMissing readable operator key file: %s\n' "${sops_age_key_file}" >&2
    printf 'register-sops-host.sh rekeys secrets with sops updatekeys, so it needs\n' >&2
    printf 'an operator age identity that can already decrypt the existing files.\n' >&2
    exit 1
  fi

  if [[ "${#operator_recipients[@]}" -eq 0 ]]; then
    printf '\nNo operator public keys found in %s\n' "${sops_age_key_file}" >&2
    exit 1
  fi

  for secret_file in "${secret_files[@]}"; do
    require_operator_decrypt_access "${sops_age_key_file}" "${secret_file}"
  done
fi

if [[ "${current_recipient}" != "${new_recipient}" ]]; then
  python3 - "${sops_config}" "${host_name}" "${new_recipient}" <<'PY'
import re
import sys

path, host, recipient = sys.argv[1], sys.argv[2], sys.argv[3]
pattern = re.compile(rf"^(\s*-\s*&{re.escape(host)}\s+)(age1[0-9a-z]+)\s*$")

with open(path, "r", encoding="utf-8") as fh:
    content = fh.read()

updated, count = pattern.subn(rf"\1{recipient}", content, count=1)
if count != 1:
    raise SystemExit(1)

with open(path, "w", encoding="utf-8") as fh:
    fh.write(updated)
PY

  printf '\nUpdated .sops.yaml for %s.\n' "${host_name}"
else
  printf '\n.sops.yaml already matches the host key.\n'
fi

for secret_file in "${secret_files[@]}"; do
  printf 'Rekeying %s\n' "${secret_file#${repo_root}/}"
  SOPS_AGE_KEY_FILE="${sops_age_key_file}" sops updatekeys --yes "${secret_file}"
done

for secret_file in "${secret_files[@]}"; do
  printf 'Verifying decrypt %s\n' "${secret_file#${repo_root}/}"
  SOPS_AGE_KEY_FILE="${host_key_file}" sops --decrypt "${secret_file}" >/dev/null
done

printf '\nHost secret registration succeeded for %s.\n' "${host_name}"
printf 'Next step:\n'
printf '  sudo nixos-rebuild test --flake .#%s\n' "${host_name}"
