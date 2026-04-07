#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/ssh-pubkey-to-age.sh [--force] [--force-operator] [--host-only]

Generate the local operator age key if missing, then generate or rotate the
machine `sops-nix` age key and print the public values you need to wire into
`.sops.yaml`.

By default it creates missing keys at:

- `~/.config/sops/age/keys.txt`
- `/var/lib/sops-nix/key.txt`

Existing keys are kept unless you explicitly force rotation. This script does
not create or modify `~/.ssh/id_ed25519`.

Examples:
  scripts/ssh-pubkey-to-age.sh
  scripts/ssh-pubkey-to-age.sh --force
  scripts/ssh-pubkey-to-age.sh --force-operator
EOF
}

force=0
force_operator=0
host_only=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=1
      shift
      ;;
    --force-operator)
      force_operator=1
      shift
      ;;
    --host-only)
      host_only=1
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

if [[ "${host_only}" -eq 1 && "${force_operator}" -eq 1 ]]; then
  printf '%s\n' "--host-only and --force-operator cannot be used together." >&2
  exit 1
fi

for cmd in age-keygen ssh-to-age grep; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf '%s is required but not on PATH\n' "$cmd" >&2
    exit 1
  fi
done

invoking_user="${SUDO_USER:-$USER}"
invoking_group="$(id -gn "${invoking_user}")"
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
operator_age_dir="$(dirname "${age_key_file}")"
system_age_dir="/var/lib/sops-nix"
system_age_key_file="${system_age_dir}/key.txt"
ssh_key_file="${invoking_home}/.ssh/id_ed25519"
ssh_pub_file="${ssh_key_file}.pub"
tmp_operator_age_key=""
tmp_system_age_key=""

cleanup() {
  if [[ -n "$tmp_operator_age_key" ]]; then
    rm -f "$tmp_operator_age_key"
  fi
  if [[ -n "$tmp_system_age_key" ]]; then
    rm -f "$tmp_system_age_key"
  fi
}

trap cleanup EXIT

if [[ "${host_only}" -eq 1 ]]; then
  printf 'Skipping operator age key bootstrap because --host-only was set.\n'
elif [[ -e "$age_key_file" && "$force_operator" -ne 1 ]]; then
  if [[ ! -r "$age_key_file" ]]; then
    printf 'Operator age key exists but is unreadable: %s\n' "$age_key_file" >&2
    printf 'Refusing to modify it implicitly. Fix permissions or rerun with --force-operator.\n' >&2
    exit 1
  fi
  if ! grep -q '^# public key:' "$age_key_file"; then
    printf 'Operator age key exists but looks malformed: %s\n' "$age_key_file" >&2
    printf 'Refusing to modify it implicitly. Repair it or rerun with --force-operator.\n' >&2
    exit 1
  fi
  printf 'Keeping existing operator age key: %s\n' "$age_key_file"
elif [[ "$EUID" -eq 0 ]]; then
  mkdir -p "$operator_age_dir"
  chmod 700 "$operator_age_dir"
  rm -f "$age_key_file"
  age-keygen -o "$age_key_file"
  chmod 600 "$age_key_file"
  chown "${invoking_user}:${invoking_group}" "$operator_age_dir" "$age_key_file"
else
  mkdir -p "$operator_age_dir"
  chmod 700 "$operator_age_dir"
  tmp_operator_age_key="$(mktemp)"
  age-keygen -o "$tmp_operator_age_key"
  install -m 600 "$tmp_operator_age_key" "$age_key_file"
  rm -f "$tmp_operator_age_key"
  tmp_operator_age_key=""
fi

if [[ -e "$system_age_key_file" && "$force" -ne 1 ]]; then
  if [[ ! -r "$system_age_key_file" ]]; then
    printf 'Host sops-nix age key exists but is unreadable: %s\n' "$system_age_key_file" >&2
    printf 'Refusing to modify it implicitly. Fix permissions or rerun with --force.\n' >&2
    exit 1
  fi
  if ! grep -q '^# public key:' "$system_age_key_file"; then
    printf 'Host sops-nix age key exists but looks malformed: %s\n' "$system_age_key_file" >&2
    printf 'Refusing to modify it implicitly. Repair it or rerun with --force.\n' >&2
    exit 1
  fi
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
  printf 'Operator recipient from this file:\n'
  grep '^# public key:' "$age_key_file" | head -n 1
else
  printf 'Not found: %s\n' "$age_key_file"
  printf 'Operator age key bootstrap was skipped.\n'
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
