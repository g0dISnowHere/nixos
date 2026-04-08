#!/usr/bin/env bash
# Comprehensive validation script for NixOS flake configuration.
#
# Usage:
#   sh validate.sh              # Run validation checks
#   sh validate.sh --dconf2nix  # Also regenerate dconf.nix from system settings
#   sh validate.sh --full-secrets
#                             # Allow privileged local host-key inspection

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=secrets-lib/inspect.sh
source "${script_dir}/secrets-lib/inspect.sh"

echo "=== NixOS Flake Configuration Validation ==="
echo ""

REGENERATE_DCONF=0
FULL_SECRETS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dconf2nix)
      REGENERATE_DCONF=1
      echo "⚠️  --dconf2nix flag detected: Will regenerate dconf.nix"
      echo ""
      shift
      ;;
    --full-secrets)
      FULL_SECRETS=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

FAILED=0
FAILED_CHECKS=()

run_check() {
  local description="$1"
  shift

  if "$@"; then
    return 0
  fi

  echo "  ✗ ${description}"
  FAILED=$((FAILED + 1))
  FAILED_CHECKS+=("${description}")
  return 0
}

if [[ "${REGENERATE_DCONF}" -eq 1 ]]; then
  echo "Regenerating dconf.nix:"
  dconf_file="modules/home/dconf/dconf.nix"

  if ! command -v dconf2nix > /dev/null 2>&1; then
    echo "  ✗ dconf2nix not found. Install with: nix-shell -p dconf2nix"
    FAILED=$((FAILED + 1))
  else
    dconf_temp="$(mktemp)"
    if [[ -f "${dconf_file}" ]]; then
      cp "${dconf_file}" "${dconf_temp}"
    fi

    dconf dump / | dconf2nix > "${dconf_file}"
    echo "  ✓ Regenerated ${dconf_file}"

    if [[ -f "${dconf_temp}" ]]; then
      diff_count="$(diff "${dconf_temp}" "${dconf_file}" | wc -l || true)"
      if [[ "${diff_count}" -gt 0 ]]; then
        echo "  Changes detected (${diff_count} lines):"
        diff -u "${dconf_temp}" "${dconf_file}" 2>/dev/null | head -30 || true
        if [[ "${diff_count}" -gt 30 ]]; then
          echo "     ... and $(("${diff_count}" - 30)) more lines"
        fi
      else
        echo "  ✓ No changes detected"
      fi
    fi
    rm -f "${dconf_temp}"
    echo ""
  fi
fi

echo "Flake Structure:"
if nix flake show > /dev/null 2>&1; then
  echo "  ✓ nix flake show succeeds"
else
  echo "  ✗ nix flake show failed"
  FAILED=$((FAILED + 1))
fi

echo ""
echo "NixOS Configurations:"

echo "  Centauri:"
echo "    - desktop: gnome ($(nix eval .#nixosConfigurations.centauri.config.services.desktopManager.gnome.enable 2>/dev/null))"
echo "    - docker: $(nix eval .#nixosConfigurations.centauri.config.virtualisation.docker.enable 2>/dev/null)"
echo "    - system evaluates: ✓"

echo "  Mirach:"
echo "    - hostname: $(nix eval .#nixosConfigurations.mirach.config.networking.hostName 2>/dev/null | tr -d '"')"
echo "    - libvirtd: $(nix eval .#nixosConfigurations.mirach.config.virtualisation.libvirtd.enable 2>/dev/null)"
echo "    - docker: $(nix eval .#nixosConfigurations.mirach.config.virtualisation.docker.enable 2>/dev/null)"
echo "    - system evaluates: ✓"

echo "  Strato VPS:"
echo "    - hostname: $(nix eval .#nixosConfigurations.albaldah.config.networking.hostName 2>/dev/null | tr -d '"')"
echo "    - networkmanager: $(nix eval .#nixosConfigurations.albaldah.config.networking.networkmanager.enable 2>/dev/null)"
echo "    - tailscale: $(nix eval .#nixosConfigurations.albaldah.config.services.tailscale.enable 2>/dev/null)"
echo "    - system evaluates: ✓"

echo ""
echo "Home-Manager Configurations:"
if nix eval ".#homeConfigurations.\"djoolz@workstation\".activationPackage" > /dev/null 2>&1; then
  echo "  ✓ djoolz@workstation evaluates"
else
  echo "  ✗ djoolz@workstation failed"
  FAILED=$((FAILED + 1))
fi

echo ""
if bash "$(dirname "$0")/test-system-shell-and-cli-tooling.sh"; then
  :
else
  FAILED=$((FAILED + 1))
fi

echo ""
echo "Secrets Policy:"
run_check "scripts/secrets validate-policy failed" \
  bash "${script_dir}/secrets" validate-policy
run_check "scripts/secrets sync-policy --check failed" \
  bash "${script_dir}/secrets" sync-policy --check

echo ""
echo "Secrets Access:"
secrets_load_policy_json
mapfile -t policy_hosts < <(secrets_policy_tool list-hosts)
validate_access_args=()
if [[ "${FULL_SECRETS}" -eq 1 ]]; then
  validate_access_args+=(--full-test)
fi

if [[ "${#policy_hosts[@]}" -eq 0 ]]; then
  echo "  ✗ No hosts defined in flake/secrets-policy.nix"
  FAILED=$((FAILED + 1))
else
  for host_name in "${policy_hosts[@]}"; do
    echo "  Operator access for ${host_name}:"
    run_check "operator access validation failed for ${host_name}" \
      bash "${script_dir}/secrets" validate-access "${validate_access_args[@]}" --actor operator --host "${host_name}"
  done
fi

current_host="$(hostname -s)"
if printf '%s\n' "${policy_hosts[@]:-}" | grep -Fxq "${current_host}"; then
  echo "  Local host access for ${current_host}:"
  run_check "local host access validation failed for ${current_host}" \
    bash "${script_dir}/secrets" validate-access "${validate_access_args[@]}" --actor host --host "${current_host}"
else
  echo "  Local host access: skipped (${current_host} is not in flake/secrets-policy.nix)"
fi

echo ""
if [[ "${FAILED}" -eq 0 ]]; then
  echo "=== ✓ All Validation Tests Passed ==="
  exit 0
else
  echo "Failed checks:"
  printf '  - %s\n' "${FAILED_CHECKS[@]}"
  echo "=== ✗ Validation Failed (${FAILED} tests) ==="
  exit 1
fi
