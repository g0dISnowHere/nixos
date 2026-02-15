#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RULES_FILE="${ROOT_DIR}/state/app-rules.md"
NIRI_CONFIG="${ROOT_DIR}/modules/compositor/niri/config.kdl"

status=0

if [ ! -f "$RULES_FILE" ]; then
  printf 'missing: %s\n' "$RULES_FILE"
  exit 1
fi

if [ ! -f "$NIRI_CONFIG" ]; then
  printf 'missing: %s\n' "$NIRI_CONFIG"
  exit 1
fi

while IFS= read -r line; do
  case "$line" in
    -*)
      app="$(printf '%s' "$line" | sed -e 's/^- *//' -e 's/ *->.*//' -e 's/ *(.*//')"
      ids="$(printf '%s' "$line" | sed -n 's/.*(\(.*\)).*/\1/p')"
      [ -n "$ids" ] || continue

      found=0
      IFS='/' read -r -a candidates <<< "$ids"
      for id in "${candidates[@]}"; do
        if grep -q "app-id=\"${id}\"" "$NIRI_CONFIG"; then
          found=1
          break
        fi
      done

      if [ "$found" -eq 0 ]; then
        printf 'missing app-id in niri config: %s (%s)\n' "$app" "$ids"
        status=1
      fi
      ;;
  esac
done < "$RULES_FILE"

exit "$status"
