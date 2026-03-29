#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sops_age_key_file="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

generic_secret="${repo_root}/secrets/services/shared/sops-test.yaml"
user_password_secret="${repo_root}/secrets/users/djoolz/password.yaml"

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "  ✗ Required command not found: ${cmd}"
    exit 1
  fi
}

decrypt_secret() {
  local secret_file="$1"
  SOPS_AGE_KEY_FILE="${sops_age_key_file}" sops --decrypt "$secret_file"
}

require_command sops

if [ ! -f "${sops_age_key_file}" ]; then
  echo "  ✗ SOPS age key file not found: ${sops_age_key_file}"
  exit 1
fi

if [ ! -f "${generic_secret}" ]; then
  echo "  ✗ Missing generic SOPS test secret: ${generic_secret}"
  exit 1
fi

if [ ! -f "${user_password_secret}" ]; then
  echo "  ✗ Missing djoolz password secret: ${user_password_secret}"
  exit 1
fi

echo "SOPS Secrets:"

generic_secret_yaml="$(decrypt_secret "${generic_secret}")"
if printf '%s\n' "${generic_secret_yaml}" | grep -Eq '^secret: sops-ok$'; then
  echo "  ✓ Generic secret decrypts and matches expected content"
else
  echo "  ✗ Generic secret decrypted, but content validation failed"
  exit 1
fi

password_secret_yaml="$(decrypt_secret "${user_password_secret}")"
password_hash_line="$(printf '%s\n' "${password_secret_yaml}" | grep -E '^passwordHash: .+$' || true)"
if [ -n "${password_hash_line}" ]; then
  echo "  ✓ djoolz password secret decrypts and exposes a passwordHash field"
else
  echo "  ✗ djoolz password secret decrypted, but content validation failed"
  exit 1
fi
