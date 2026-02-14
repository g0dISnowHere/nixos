#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_DIR="${ROOT_DIR}/health/checks"

status=0

for check in "${CHECK_DIR}"/*.sh; do
  [ -e "$check" ] || continue
  printf '==> %s\n' "$(basename "$check")"
  if bash "$check"; then
    printf 'ok\n\n'
  else
    printf 'FAIL\n\n'
    status=1
  fi
done

exit "$status"
