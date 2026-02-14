#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_BASE="${HOME}/.config"

link_path() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  printf 'linked %s -> %s\n' "$dest" "$src"
}

link_path "${ROOT_DIR}/modules/compositor/niri/config.kdl" "${TARGET_BASE}/niri/config.kdl"
link_path "${ROOT_DIR}/modules/ui/waybar" "${TARGET_BASE}/waybar"
link_path "${ROOT_DIR}/modules/ui/mako" "${TARGET_BASE}/mako"
link_path "${ROOT_DIR}/modules/launcher/fuzzel" "${TARGET_BASE}/fuzzel"
