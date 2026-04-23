#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_BASE="${HOME}/.config"
BACKUP_ROOT="${HOME}/.local/state/dotfiles-link-backups"

backup_path_for() {
  local dest="$1"
  local relative="${dest#${HOME}/}"
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  printf '%s/%s.%s' "$BACKUP_ROOT" "$relative" "$timestamp"
}

link_path() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    printf 'already linked %s -> %s\n' "$dest" "$src"
    return
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ -L "$dest" ]; then
      rm "$dest"
    else
      local backup
      backup="$(backup_path_for "$dest")"
      mkdir -p "$(dirname "$backup")"
      mv "$dest" "$backup"
      printf 'backed up %s -> %s\n' "$dest" "$backup"
    fi
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sT "$src" "$dest"
  printf 'linked %s -> %s\n' "$dest" "$src"
}

link_path "${ROOT_DIR}/modules/compositor/niri/config.kdl" "${TARGET_BASE}/niri/config.kdl"
link_path "${ROOT_DIR}/modules/compositor/niri/swaylock-noctalia.sh" "${TARGET_BASE}/niri/swaylock-noctalia.sh"
link_path "${ROOT_DIR}/modules/compositor/nirinit" "${TARGET_BASE}/nirinit"
link_path "${ROOT_DIR}/modules/ui/waybar" "${TARGET_BASE}/waybar"
link_path "${ROOT_DIR}/modules/ui/mako" "${TARGET_BASE}/mako"
link_path "${ROOT_DIR}/modules/launcher/fuzzel" "${TARGET_BASE}/fuzzel"
link_path "${ROOT_DIR}/modules/ui/noctalia" "${TARGET_BASE}/noctalia"
link_path "${ROOT_DIR}/shell/zshrc" "${HOME}/.zshrc"
