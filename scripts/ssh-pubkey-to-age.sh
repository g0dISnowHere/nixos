#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/ssh-pubkey-to-age.sh [--force]

Generate or rotate only the machine `sops-nix` age key, then print the public
values you need to wire into `.sops.yaml`.

This script does not create, rotate, relabel, or overwrite:

- `~/.config/sops/age/keys.txt`
- `~/.ssh/id_ed25519`

It only manages `/var/lib/sops-nix/key.txt`.

Examples:
  scripts/ssh-pubkey-to-age.sh
  scripts/ssh-pubkey-to-age.sh --force
EOF
}

force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=1
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

for cmd in age-keygen ssh-to-age grep; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf '%s is required but not on PATH\n' "$cmd" >&2
    exit 1
  fi
done

invoking_user="${SUDO_USER:-$USER}"
invoking_home="$(getent passwd "${invoking_user}" | cut -d: -f6)"
if [[ -z "${invoking_home}" ]]; then
  printf 'Could not resolve home directory for user: %s\n' "${invoking_user}" >&2
  exit 1
fi

read_host_public_key() {
  local key_file="$1"

  if [[ -r "${key_file}" ]]; then
    grep '^# public key:' "${key_file}"
  else
    sudo grep '^# public key:' "${key_file}"
  fi
}

age_key_file="${invoking_home}/.config/sops/age/keys.txt"
system_age_dir="/var/lib/sops-nix"
system_age_key_file="${system_age_dir}/key.txt"
ssh_key_file="${invoking_home}/.ssh/id_ed25519"
ssh_pub_file="${ssh_key_file}.pub"
tmp_system_age_key=""

cleanup() {
  if [[ -n "$tmp_system_age_key" ]]; then
    rm -f "$tmp_system_age_key"
  fi
}

trap cleanup EXIT

if [[ -e "$system_age_key_file" && "$force" -ne 1 ]]; then
  printf 'Keeping existing sops-nix host age key: %s\n' "$system_age_key_file"
elif [[ "$EUID" -eq 0 ]]; then
  mkdir -p "$system_age_dir"
  rm -f "$system_age_key_file"
  age-keygen -o "$system_age_key_file"
  chmod 600 "$system_age_key_file"
else
  tmp_system_age_key="$(mktemp)"
  age-keygen -o "$tmp_system_age_key"

  printf '\nInstalling sops-nix host age key to %s (sudo may prompt)...\n' "$system_age_key_file"
  sudo mkdir -p "$system_age_dir"
  sudo install -m 600 "$tmp_system_age_key" "$system_age_key_file"
  rm -f "$tmp_system_age_key"
  tmp_system_age_key=""
fi

printf '\n=== Local age identity ===\n'
if [[ -e "$age_key_file" ]]; then
  printf 'Stored in: %s\n' "$age_key_file"
  printf 'Existing operator recipient from this file:\n'
  grep '^# public key:' "$age_key_file"
else
  printf 'Not found: %s\n' "$age_key_file"
  printf 'This script does not create or modify the operator age key.\n'
fi

printf '\n=== sops-nix host age identity ===\n'
printf 'Stored in: %s\n' "$system_age_key_file"
printf 'Use this age public key as the machine recipient in .sops.yaml:\n'
read_host_public_key "$system_age_key_file"

printf '\n=== SSH keypair ===\n'
if [[ -e "$ssh_key_file" && -e "$ssh_pub_file" ]]; then
  read -r ssh_key_type ssh_key_data ssh_key_comment < "$ssh_pub_file"
  printf 'Stored in: %s\n' "$ssh_key_file"
  printf 'Existing SSH public key for remote authorized_keys:\n'
  if [[ -n "${ssh_key_type:-}" && -n "${ssh_key_data:-}" ]]; then
    printf '%s %s %s\n' "$ssh_key_type" "$ssh_key_data" "${ssh_key_comment:-}"
  else
    cat "$ssh_pub_file"
  fi
else
  printf 'Not found: %s\n' "$ssh_key_file"
  printf 'This script does not create or modify the SSH keypair.\n'
fi

printf '\n=== SSH-derived age recipient ===\n'
if [[ -e "$ssh_pub_file" ]]; then
  printf 'Optional and separate from the sops-nix host key above:\n'
  ssh-to-age < "$ssh_pub_file"
else
  printf 'SSH public key not found, so no SSH-derived age recipient is available.\n'
fi
