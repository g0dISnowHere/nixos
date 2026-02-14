#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_BASE="${HOME}/.config"

backup_if_needed() {
  local dest="$1"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    local ts
    ts="$(date +%Y%m%d%H%M%S)"
    mv "$dest" "${dest}.bak.${ts}"
  fi
}

link_path() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  backup_if_needed "$dest"
  ln -sfn "$src" "$dest"
  printf 'linked %s -> %s\n' "$dest" "$src"
}

link_path "${ROOT_DIR}/modules/compositor/niri/config.kdl" "${TARGET_BASE}/niri/config.kdl"
link_path "${ROOT_DIR}/modules/ui/waybar" "${TARGET_BASE}/waybar"
link_path "${ROOT_DIR}/modules/ui/mako" "${TARGET_BASE}/mako"
