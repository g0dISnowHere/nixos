#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NIRINIT_CONFIG="${ROOT_DIR}/modules/compositor/nirinit/config.toml"

status=0

if [ ! -f "$NIRINIT_CONFIG" ]; then
  printf 'missing: %s\n' "$NIRINIT_CONFIG"
  exit 1
fi

if grep -q '^[[:space:]]*save_interval[[:space:]]*=' "$NIRINIT_CONFIG"; then
  printf 'invalid nirinit config: save_interval must be passed via systemd ExecStart, not config.toml\n'
  status=1
fi

if grep -q '^[[:space:]]*\\[ignore\\][[:space:]]*$' "$NIRINIT_CONFIG"; then
  printf 'invalid nirinit config: [ignore] is not supported, use [skip] with apps = [...]\n'
  status=1
fi

exit "$status"
