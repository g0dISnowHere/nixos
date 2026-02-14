#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_BASE="${HOME}/.config"

unlink_path() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    local target
    target="$(readlink "$dest")"
    if [ "$target" = "$src" ]; then
      rm "$dest"
      printf 'unlinked %s\n' "$dest"
    fi
  fi
}

unlink_path "${ROOT_DIR}/modules/compositor/niri/config.kdl" "${TARGET_BASE}/niri/config.kdl"
unlink_path "${ROOT_DIR}/modules/compositor/nirinit" "${TARGET_BASE}/nirinit"
unlink_path "${ROOT_DIR}/modules/ui/waybar" "${TARGET_BASE}/waybar"
unlink_path "${ROOT_DIR}/modules/ui/mako" "${TARGET_BASE}/mako"
unlink_path "${ROOT_DIR}/modules/launcher/fuzzel" "${TARGET_BASE}/fuzzel"
unlink_path "${ROOT_DIR}/modules/ui/noctalia" "${TARGET_BASE}/noctalia"
