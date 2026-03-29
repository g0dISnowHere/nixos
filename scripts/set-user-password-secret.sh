#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
username="djoolz"
secret_file=""
sops_path_hint=""
sops_age_key_file="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
password=""
read_from_stdin=0
lock_password=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Create or rotate a SOPS-encrypted user password secret.

Options:
  --user NAME           Username to manage (default: djoolz)
  --secret-file PATH    Override the target secret path
  --stdin               Read the password from stdin instead of prompting
  --lock                Store "!" as passwordHash to lock the account
  -h, --help            Show this help

Examples:
  $(basename "$0")
  printf '%s\n' 'new-password' | $(basename "$0") --stdin
  $(basename "$0") --user djoolz --lock
EOF
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command not found: ${cmd}" >&2
    exit 1
  fi
}

prompt_password() {
  local first=""
  local second=""

  printf 'Enter password for %s: ' "${username}" >&2
  read -r -s first
  echo
  printf 'Confirm password for %s: ' "${username}" >&2
  read -r -s second
  echo

  if [ -z "${first}" ]; then
    echo "Password must not be empty" >&2
    exit 1
  fi

  if [ "${first}" != "${second}" ]; then
    echo "Passwords did not match" >&2
    exit 1
  fi

  password="${first}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --user)
      username="${2:?missing value for --user}"
      shift 2
      ;;
    --secret-file)
      secret_file="${2:?missing value for --secret-file}"
      shift 2
      ;;
    --stdin)
      read_from_stdin=1
      shift
      ;;
    --lock)
      lock_password=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "${secret_file}" ]; then
  secret_file="${repo_root}/secrets/users/${username}/password.yaml"
fi

case "${secret_file}" in
  "${repo_root}/"*)
    sops_path_hint="${secret_file#"${repo_root}/"}"
    ;;
  *)
    echo "--secret-file must stay inside the repository: ${repo_root}" >&2
    exit 1
    ;;
esac

if [ "${read_from_stdin}" -eq 1 ] && [ "${lock_password}" -eq 1 ]; then
  echo "Use either --stdin or --lock, not both" >&2
  exit 1
fi

require_command mkpasswd
require_command sops

if [ ! -f "${sops_age_key_file}" ]; then
  echo "SOPS age key file not found: ${sops_age_key_file}" >&2
  exit 1
fi

mkdir -p "$(dirname "${secret_file}")"

if [ "${lock_password}" -eq 1 ]; then
  password_hash="!"
elif [ "${read_from_stdin}" -eq 1 ]; then
  IFS= read -r password
  if [ -z "${password}" ]; then
    echo "Password from stdin must not be empty" >&2
    exit 1
  fi
else
  prompt_password
fi

if [ "${lock_password}" -eq 0 ]; then
  password_hash="$(printf '%s' "${password}" | mkpasswd --method=yescrypt --stdin)"
fi

tmp_plaintext="$(mktemp)"
cleanup() {
  rm -f "${tmp_plaintext}"
}
trap cleanup EXIT

cat > "${tmp_plaintext}" <<EOF
passwordHash: ${password_hash@Q}
managedBy: scripts/set-user-password-secret.sh
updatedAt: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

SOPS_AGE_KEY_FILE="${sops_age_key_file}" \
  sops --encrypt \
  --filename-override "${sops_path_hint}" \
  --input-type yaml \
  --output-type yaml \
  --output "${secret_file}" \
  "${tmp_plaintext}"

echo "Wrote encrypted password secret to ${secret_file}"
