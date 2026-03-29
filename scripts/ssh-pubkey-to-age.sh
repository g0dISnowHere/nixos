#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/ssh-pubkey-to-age.sh [--force]

Generate local operator/host key material for sops and SSH, then print the
public values you need to wire into `.sops.yaml`, `authorized_keys`, and the
local `~/.config/sops/age/keys.txt` setup.

This script manages local key material only. It does not manage `~/.ssh/config`
or other SSH client settings from Home Manager.

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

read -r ssh_key_type ssh_key_data ssh_key_comment < "$ssh_pub_file"

printf '\n=== Local age identity ===\n'
printf 'Stored in: %s\n' "$age_key_file"
printf 'Use this age public key as an operator recipient in .sops.yaml:\n'
grep '^# public key:' "$age_key_file"

printf '\n=== SSH keypair ===\n'
printf 'Stored in: %s\n' "$ssh_key_file"
printf 'Home Manager should manage SSH client config; this script only creates or inspects the keypair.\n'
printf 'Use this SSH public key for remote authorized_keys:\n'
if [[ -n "${ssh_key_type:-}" && -n "${ssh_key_data:-}" ]]; then
  printf '%s %s %s\n' "$ssh_key_type" "$ssh_key_data" "$ssh_comment"
else
  cat "$ssh_pub_file"
fi

if [[ "${ssh_key_comment:-}" != "$ssh_comment" ]]; then
  printf '\nSSH key comment note:\n'
  printf 'The existing SSH key comment does not match the preferred format.\n'
  printf 'Current comment:   %s\n' "${ssh_key_comment:-<none>}"
  printf 'Preferred comment: %s\n' "$ssh_comment"
  printf 'Relabel without rotating the key? [y/N]: '
  read -r relabel_reply
  if [[ "$relabel_reply" =~ ^[Yy]$ ]]; then
    ssh-keygen -c -P "" -f "$ssh_key_file" -C "$ssh_comment"
  else
    printf 'Skipped relabel. Run manually if needed:\n'
    printf 'ssh-keygen -c -f %s -C \"%s\"\n' "$ssh_key_file" "$ssh_comment"
  fi
fi

printf '\n=== SSH-derived age recipient ===\n'
printf 'Use this converted recipient in .sops.yaml if you want this SSH key to decrypt secrets:\n'
ssh-to-age < "$ssh_pub_file"
