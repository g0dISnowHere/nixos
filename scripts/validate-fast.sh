#!/usr/bin/env bash
# Fast validation script for pre-commit and quick local checks.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Fast Validation ==="
echo ""

failed=0
failed_checks=()

run_check() {
  local description="$1"
  shift

  if "$@"; then
    return 0
  fi

  echo "  ✗ ${description}"
  failed=$((failed + 1))
  failed_checks+=("${description}")
  return 0
}

echo "Flake Structure:"
if nix flake show > /dev/null 2>&1; then
  echo "  ✓ nix flake show succeeds"
else
  echo "  ✗ nix flake show failed"
  failed=$((failed + 1))
  failed_checks+=("nix flake show failed")
fi

echo ""
echo "Key Evaluations:"
run_check "nixosConfigurations.centauri failed to evaluate" \
  nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
run_check "nixosConfigurations.mirach failed to evaluate" \
  nix eval .#nixosConfigurations.mirach.config.system.build.toplevel
run_check "nixosConfigurations.albaldah failed to evaluate" \
  nix eval .#nixosConfigurations.albaldah.config.system.build.toplevel
run_check "homeConfigurations.djoolz@workstation failed to evaluate" \
  nix eval ".#homeConfigurations.\"djoolz@workstation\".activationPackage"

echo ""
echo "Secrets Policy:"
run_check "scripts/secrets validate-policy failed" \
  bash "${script_dir}/secrets" validate-policy
run_check "scripts/secrets sync-policy --check failed" \
  bash "${script_dir}/secrets" sync-policy --check

echo ""
if [[ "${failed}" -eq 0 ]]; then
  echo "=== ✓ Fast Validation Passed ==="
  exit 0
fi

echo "Failed checks:"
printf '  - %s\n' "${failed_checks[@]}"
echo "=== ✗ Fast Validation Failed (${failed} tests) ==="
exit 1
