#!/usr/bin/env bash
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia"
wallpapers_json="$cache_dir/wallpapers.json"
colors_json="$config_dir/colors.json"

primary="#52befa"
if [[ -f "$colors_json" ]]; then
  primary="$(jq -r '.mPrimary // empty' "$colors_json" 2>/dev/null || true)"
fi
if [[ -z "$primary" || "$primary" == "null" ]]; then
  primary="#52befa"
fi
accent="${primary#\#}"

image_args=()
if [[ -f "$wallpapers_json" ]]; then
  while IFS= read -r entry; do
    output="${entry%%=*}"
    path="${entry#*=}"
    if [[ -n "$path" && -f "$path" ]]; then
      image_args+=(--image "${output}:${path}")
    fi
  done < <(jq -r '.wallpapers | to_entries[] | "\(.key)=\(.value)"' "$wallpapers_json" 2>/dev/null || true)

  if [[ ${#image_args[@]} -eq 0 ]]; then
    default_wallpaper="$(jq -r '.defaultWallpaper // empty' "$wallpapers_json" 2>/dev/null || true)"
    if [[ -n "$default_wallpaper" && -f "$default_wallpaper" ]]; then
      image_args+=(--image "$default_wallpaper")
    fi
  fi
fi

ring="#${accent}cc"
key_hl="#${accent}ff"
text="#e6e6e6ff"
inside="#00000055"
line="#00000000"
separator="#00000000"

exec swaylock \
  --indicator \
  --indicator-radius 90 \
  --indicator-thickness 3 \
  --inside-color "$inside" \
  --ring-color "$ring" \
  --key-hl-color "$key_hl" \
  --line-color "$line" \
  --separator-color "$separator" \
  --text-color "$text" \
  --fade-in 0.2 \
  "${image_args[@]}"
