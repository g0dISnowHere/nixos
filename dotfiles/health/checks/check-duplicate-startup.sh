#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NIRI_CONFIG="${ROOT_DIR}/modules/compositor/niri/config.kdl"

status=0

if [ ! -f "$NIRI_CONFIG" ]; then
  printf 'missing: %s\n' "$NIRI_CONFIG"
  exit 1
fi

has_niri_autostart() {
  local app="$1"
  if grep -q 'spawn-at-startup' "$NIRI_CONFIG" && grep -q "$app" "$NIRI_CONFIG"; then
    return 0
  fi
  return 1
}

has_systemd_unit() {
  local unit="$1"
  local path

  for path in \
    "$HOME/.config/systemd/user/${unit}" \
    "$HOME/.config/systemd/user/default.target.wants/${unit}" \
    "$HOME/.config/systemd/user/graphical-session.target.wants/${unit}" \
    "/etc/systemd/user/${unit}" \
    "/etc/systemd/user/default.target.wants/${unit}" \
    "/etc/systemd/user/graphical-session.target.wants/${unit}"; do
    if [ -e "$path" ]; then
      return 0
    fi
  done

  return 1
}

check_app() {
  local label="$1"
  local unit="$2"
  local needle="$3"

  if has_niri_autostart "$needle" && has_systemd_unit "$unit"; then
    printf 'duplicate startup: %s (niri + systemd)\n' "$label"
    status=1
  fi
}

check_app "waybar" "waybar.service" "waybar"
check_app "mako" "mako.service" "mako"
check_app "nirinit" "nirinit.service" "nirinit"

exit "$status"
