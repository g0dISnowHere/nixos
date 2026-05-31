#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/repair-mirach-gdm-users.sh [--apply] [--yes] [--restart-display-manager]

Diagnoses and repairs the mirach GDM greeter account failure caused by corrupted
local account state. Diagnosis is read-only by default.

Options:
  --apply                    Back up account files, reset corrupted gid-map,
                             and rerun /run/current-system/activate.
  --yes                      Do not prompt before applying the repair.
  --restart-display-manager  Restart display-manager.service after repair.
  -h, --help                 Show this help.
EOF
}

apply=0
yes=0
restart_display_manager=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      apply=1
      shift
      ;;
    --yes)
      yes=1
      shift
      ;;
    --restart-display-manager)
      restart_display_manager=1
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

host="$(hostname -s)"
if [[ "$host" != "mirach" ]]; then
  printf 'Refusing to run: this repair is scoped to mirach, current host is %s\n' "$host" >&2
  exit 1
fi

if [[ "$apply" -eq 0 && "$yes" -eq 1 ]]; then
  printf '%s\n' '--yes only has an effect with --apply' >&2
  exit 1
fi

has_nul_bytes() {
  local path="$1"
  perl -e 'local $/; my $s = <>; exit(($s =~ /\0/) ? 0 : 1)' "$path"
}

json_valid() {
  local path="$1"
  python3 -m json.tool "$path" >/dev/null 2>&1
}

check_status() {
  local description="$1"
  shift

  if "$@"; then
    printf '  [ok] %s\n' "$description"
    return 0
  fi

  printf '  [fail] %s\n' "$description"
  return 1
}

no_nul_bytes() {
  ! has_nul_bytes "$1"
}

gdm_greeter_declared() {
  local manifest="$1"
  python3 - "$manifest" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    spec = json.load(handle)

users = {user["name"] for user in spec["users"]}
sys.exit(0 if "gdm-greeter" in users else 1)
PY
}

passwd_entry_exists() {
  getent passwd "$1" >/dev/null
}

find_users_manifest() {
  sed -n 's|.* \(/nix/store/[^ ]*-users-groups\.json\).*|\1|p' /run/current-system/activate | head -n 1
}

diagnose() {
  local failed=0
  local users_manifest
  users_manifest="$(find_users_manifest)"

  printf 'mirach GDM greeter account repair diagnosis\n'
  printf 'host: %s\n' "$host"
  printf '\n'

  printf 'Runtime state:\n'
  check_status "/etc/passwd has no NUL bytes" no_nul_bytes /etc/passwd || failed=$((failed + 1))
  check_status "/var/lib/nixos/gid-map is valid JSON" json_valid /var/lib/nixos/gid-map || failed=$((failed + 1))
  check_status "/var/lib/nixos/uid-map is valid JSON" json_valid /var/lib/nixos/uid-map || failed=$((failed + 1))
  check_status "gdm-greeter is visible through NSS" passwd_entry_exists gdm-greeter || failed=$((failed + 1))

  printf '\n'
  printf 'Current generation:\n'
  if [[ -n "$users_manifest" && -r "$users_manifest" ]]; then
    printf '  users manifest: %s\n' "$users_manifest"
    check_status "users manifest declares gdm-greeter" gdm_greeter_declared "$users_manifest" || failed=$((failed + 1))
  else
    printf '  [fail] users manifest could not be found from /run/current-system/activate\n'
    failed=$((failed + 1))
  fi

  printf '\n'
  if [[ "$failed" -eq 0 ]]; then
    printf 'Result: ok, no repair needed\n'
  else
    printf 'Result: fail (%s checks). Run with --apply to repair account activation state.\n' "$failed"
  fi

  return "$failed"
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    printf 'Repair requires root. Run:\n' >&2
    printf '  sudo %s --apply\n' "$0" >&2
    exit 1
  fi
}

confirm_apply() {
  if [[ "$yes" -eq 1 ]]; then
    return 0
  fi

  cat <<'EOF'
This will:
  - back up /etc/passwd, /etc/group, /etc/shadow, /var/lib/nixos/uid-map,
    and /var/lib/nixos/gid-map under /root
  - replace /var/lib/nixos/gid-map with {}
  - rerun /run/current-system/activate so NixOS rewrites declared users/groups

It does not hand-create GNOME users and does not change Nix config.
EOF
  printf 'Apply repair? [y/N] '
  read -r answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *)
      printf 'Aborted\n'
      exit 1
      ;;
  esac
}

backup_account_state() {
  local backup_dir="$1"
  install -d -m 0700 "$backup_dir"

  local path
  for path in \
    /etc/passwd \
    /etc/group \
    /etc/shadow \
    /etc/subuid \
    /etc/subgid \
    /var/lib/nixos/uid-map \
    /var/lib/nixos/gid-map \
    /var/lib/nixos/declarative-users \
    /var/lib/nixos/declarative-groups; do
    if [[ -e "$path" ]]; then
      cp -a "$path" "$backup_dir"/
    fi
  done
}

apply_repair() {
  require_root
  confirm_apply

  local backup_dir
  backup_dir="/root/mirach-gdm-account-repair-$(date +%Y%m%dT%H%M%S%z)"

  printf 'Backing up account state to %s\n' "$backup_dir"
  backup_account_state "$backup_dir"

  printf 'Resetting corrupted /var/lib/nixos/gid-map\n'
  printf '{}\n' > /var/lib/nixos/gid-map
  chmod 0644 /var/lib/nixos/gid-map

  printf 'Running current NixOS activation\n'
  /run/current-system/activate

  printf '\n'
  printf 'Post-repair validation:\n'
  check_status "/etc/passwd has no NUL bytes" no_nul_bytes /etc/passwd
  check_status "/var/lib/nixos/gid-map is valid JSON" json_valid /var/lib/nixos/gid-map
  check_status "gdm-greeter is visible through NSS" passwd_entry_exists gdm-greeter
  check_status "gdm-greeter-1 is visible through NSS" passwd_entry_exists gdm-greeter-1
  check_status "gdm-greeter-2 is visible through NSS" passwd_entry_exists gdm-greeter-2
  check_status "gdm-greeter-3 is visible through NSS" passwd_entry_exists gdm-greeter-3
  check_status "gdm-greeter-4 is visible through NSS" passwd_entry_exists gdm-greeter-4

  if [[ "$restart_display_manager" -eq 1 ]]; then
    printf '\nRestarting display-manager.service\n'
    systemctl restart display-manager.service
    systemctl --no-pager --full status display-manager.service
  else
    printf '\nDisplay manager was not restarted. To restart it now:\n'
    printf '  sudo systemctl restart display-manager.service\n'
  fi

  printf '\nBackup: %s\n' "$backup_dir"
}

if [[ "$apply" -eq 1 ]]; then
  apply_repair
else
  diagnose
fi
