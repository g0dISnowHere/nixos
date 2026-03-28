#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/ssh-pubkey-to-age.sh [--force]

Generate local operator/host key material for sops and SSH, then print the
public values you need to wire into .sops.yaml and remote authorized_keys.

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

for cmd in age-keygen ssh-keygen ssh-to-age grep hostname date; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf '%s is required but not on PATH\n' "$cmd" >&2
    exit 1
  fi
done

age_dir="${HOME}/.config/sops/age"
age_key_file="${age_dir}/keys.txt"
ssh_dir="${HOME}/.ssh"
ssh_key_file="${ssh_dir}/id_ed25519"
ssh_pub_file="${ssh_key_file}.pub"
ssh_comment="${USER}@$(hostname)-$(date +%F)"

mkdir -p "$age_dir" "$ssh_dir"
chmod 700 "$ssh_dir"

if [[ -e "$age_key_file" && "$force" -ne 1 ]]; then
  printf 'Keeping existing age key: %s\n' "$age_key_file"
else
  rm -f "$age_key_file"
  age-keygen -o "$age_key_file"
  chmod 600 "$age_key_file"
fi

if [[ -e "$ssh_key_file" && "$force" -ne 1 ]]; then
  printf 'Keeping existing SSH key: %s\n' "$ssh_key_file"
else
  rm -f "$ssh_key_file" "$ssh_pub_file"
  ssh-keygen -t ed25519 -a 64 -f "$ssh_key_file" -C "$ssh_comment" -N ""
  chmod 600 "$ssh_key_file"
  chmod 644 "$ssh_pub_file"
fi

printf '\nOperator age public key:\n'
grep '^# public key:' "$age_key_file"

printf '\nSSH public key:\n'
cat "$ssh_pub_file"

printf '\nSSH recipient for .sops.yaml:\n'
ssh-to-age < "$ssh_pub_file"
