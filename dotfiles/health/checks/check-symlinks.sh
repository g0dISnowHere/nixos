#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

expect_niri="${ROOT_DIR}/modules/compositor/niri/config.kdl"
expect_nirinit="${ROOT_DIR}/modules/compositor/nirinit"
expect_waybar="${ROOT_DIR}/modules/ui/waybar"
expect_mako="${ROOT_DIR}/modules/ui/mako"
expect_noctalia_settings="${ROOT_DIR}/modules/ui/noctalia/settings.json"
expect_noctalia_plugins_json="${ROOT_DIR}/modules/ui/noctalia/plugins.json"
expect_noctalia_colors="${ROOT_DIR}/modules/ui/noctalia/colors.json"
expect_noctalia_plugins="${ROOT_DIR}/modules/ui/noctalia/plugins"
expect_noctalia_colorschemes="${ROOT_DIR}/modules/ui/noctalia/colorschemes"

status=0

check_link() {
  local dest="$1"
  local expect="$2"
  local actual

  actual="$(readlink -f "$dest" 2>/dev/null || true)"
  if [ -z "$actual" ]; then
    printf 'missing: %s\n' "$dest"
    status=1
    return
  fi

  if [ "$actual" != "$expect" ]; then
    printf 'drift: %s -> %s (expected %s)\n' "$dest" "$actual" "$expect"
    status=1
  fi
}

check_link "$HOME/.config/niri/config.kdl" "$expect_niri"
check_link "$HOME/.config/nirinit" "$expect_nirinit"
check_link "$HOME/.config/waybar" "$expect_waybar"
check_link "$HOME/.config/mako" "$expect_mako"
check_link "$HOME/.config/noctalia/settings.json" "$expect_noctalia_settings"
check_link "$HOME/.config/noctalia/plugins.json" "$expect_noctalia_plugins_json"
check_link "$HOME/.config/noctalia/colors.json" "$expect_noctalia_colors"
check_link "$HOME/.config/noctalia/plugins" "$expect_noctalia_plugins"
check_link "$HOME/.config/noctalia/colorschemes" "$expect_noctalia_colorschemes"

exit "$status"
